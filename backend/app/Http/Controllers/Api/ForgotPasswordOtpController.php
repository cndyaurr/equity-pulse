<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PasswordChangeOtp;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class ForgotPasswordOtpController extends Controller
{
    /**
     * Meminta OTP pemulihan password melalui email.
     */
    public function requestOtp(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $email = strtolower(trim($validated['email']));
        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();

        // Respons dibuat sama agar tidak membocorkan keberadaan akun.
        if (!$user || empty($user->email)) {
            return response()->json([
                'success' => true,
                'message' => 'Jika email terdaftar, kode OTP akan dikirim.',
            ]);
        }

        $limitKey = 'forgot-password-otp:' . $user->id;

        if (RateLimiter::tooManyAttempts($limitKey, 3)) {
            return response()->json([
                'message' => 'Terlalu banyak permintaan OTP. Silakan coba lagi nanti.',
            ], 429);
        }

        $otp = (string) random_int(100000, 999999);

        // Menghapus OTP pemulihan sebelumnya saja.
        PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'forgot_password')
            ->where('method', 'email')
            ->delete();

        $otpRecord = PasswordChangeOtp::create([
            'user_id' => $user->id,
            'purpose' => 'forgot_password',
            'method' => 'email',
            'otp_hash' => Hash::make($otp),
            'expires_at' => now()->addMinutes(5),
            'attempts' => 0,
        ]);

        try {
            Mail::raw(
                "Kode OTP pemulihan password akun EQUICKLY Anda adalah: {$otp}\n\n"
                . "Kode berlaku selama 5 menit.\n"
                . "Jangan bagikan kode ini kepada siapa pun.",
                function ($message) use ($user) {
                    $message->to($user->email)
                        ->subject('OTP Pemulihan Password EQUICKLY');
                }
            );
        } catch (\Throwable $e) {
            $otpRecord->delete();

            report($e);

            return response()->json([
                'message' => 'Gagal mengirim OTP email. Silakan coba lagi.',
            ], 500);
        }

        RateLimiter::hit($limitKey, 600);

        return response()->json([
            'success' => true,
            'message' => 'Jika email terdaftar, kode OTP akan dikirim.',
        ]);
    }

    /**
     * Memverifikasi OTP pemulihan.
     */
    public function verifyOtp(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'otp' => ['required', 'string', 'size:6', 'regex:/^[0-9]{6}$/'],
        ]);

        $email = strtolower(trim($validated['email']));

        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();

        if (!$user) {
            return response()->json([
                'message' => 'OTP tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        $otpRecord = PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'forgot_password')
            ->where('method', 'email')
            ->first();

        if (!$otpRecord) {
            return response()->json([
                'message' => 'OTP tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        if (
            $otpRecord->verified_at !== null ||
            now()->greaterThanOrEqualTo($otpRecord->expires_at) ||
            $otpRecord->attempts >= 5
        ) {
            $otpRecord->delete();

            return response()->json([
                'message' => 'OTP tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        if (!Hash::check($validated['otp'], $otpRecord->otp_hash)) {
            $otpRecord->increment('attempts');

            return response()->json([
                'message' => 'OTP tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        $verificationToken = Str::random(64);

        $otpRecord->update([
            'verified_at' => now(),
            'verification_token_hash' => Hash::make($verificationToken),
            'verification_expires_at' => now()->addMinutes(10),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'OTP berhasil diverifikasi.',
            'verification_token' => $verificationToken,
        ]);
    }

    /**
     * Mengganti password setelah OTP terverifikasi.
     */
    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'verification_token' => ['required', 'string'],
            'password' => [
                'required',
                'confirmed',
                Password::min(8),
            ],
        ]);

        $email = strtolower(trim($validated['email']));

        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();

        if (!$user) {
            return response()->json([
                'message' => 'Verifikasi tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        $otpRecord = PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'forgot_password')
            ->where('method', 'email')
            ->whereNotNull('verified_at')
            ->first();

        if (
            !$otpRecord ||
            !$otpRecord->verification_expires_at ||
            now()->greaterThanOrEqualTo($otpRecord->verification_expires_at) ||
            empty($otpRecord->verification_token_hash) ||
            !Hash::check(
                $validated['verification_token'],
                $otpRecord->verification_token_hash
            )
        ) {
            return response()->json([
                'message' => 'Verifikasi tidak valid atau sudah kedaluwarsa.',
            ], 422);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        $otpRecord->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diperbarui. Silakan login kembali.',
        ]);
    }
}
