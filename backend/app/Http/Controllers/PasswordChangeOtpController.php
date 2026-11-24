<?php

namespace App\Http\Controllers;

use App\Models\PasswordChangeOtp;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class PasswordChangeOtpController extends Controller
{
    /**
     * Meminta OTP melalui email atau WhatsApp.
     */
    public function requestOtp(Request $request)
    {
        $request->validate([
            'method' => 'required|in:email,whatsapp',
        ]);

        $user = $request->user();
        $method = $request->input('method');

        // Rate limit permintaan OTP per user dan channel.
        $limitKey = 'password-otp-request:' . $user->id . ':' . $method;

        if (RateLimiter::tooManyAttempts($limitKey, 3)) {
            return response()->json([
                'message' => 'Terlalu banyak permintaan OTP. Silakan coba lagi nanti.',
            ], 429);
        }

        // WhatsApp belum terintegrasi dengan provider.
        if ($method === 'whatsapp') {
            return response()->json([
                'message' => 'Pengiriman OTP WhatsApp belum tersedia.',
            ], 501);
        }

        if (empty($user->email)) {
            return response()->json([
                'message' => 'Akun tidak memiliki email.',
            ], 422);
        }

        $otp = (string) random_int(100000, 999999);

        // Hapus OTP profil sebelumnya untuk user dan channel yang sama.
        PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'profile')
            ->where('method', $method)
            ->delete();

        // Simpan OTP baru.
        $otpRecord = PasswordChangeOtp::create([
            'user_id' => $user->id,
            'method' => $method,
            'purpose' => 'profile',
            'otp_hash' => Hash::make($otp),
            'expires_at' => now()->addMinutes(5),
            'attempts' => 0,
        ]);

        try {
            Mail::raw(
                "Kode OTP untuk mengganti password akun EQUICKLY Anda adalah: {$otp}\n\n"
                . "Kode berlaku selama 5 menit. Jangan bagikan kode ini kepada siapa pun.",
                function ($message) use ($user) {
                    $message->to($user->email)
                        ->subject('OTP Penggantian Password EQUICKLY');
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
            'message' => 'OTP berhasil dikirim ke email Anda.',
        ]);
    }

    /**
     * Memverifikasi OTP dan menghasilkan verification token.
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'method' => 'required|in:email,whatsapp',
            'otp' => 'required|string|size:6',
        ]);

        $user = $request->user();
        $method = $request->input('method');

        // Ambil OTP khusus untuk perubahan password profil.
        $otpRecord = PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'profile')
            ->where('method', $method)
            ->first();

        if (!$otpRecord) {
            return response()->json([
                'message' => 'OTP tidak ditemukan. Silakan meminta OTP baru.',
            ], 422);
        }

        if ($otpRecord->verified_at !== null) {
            return response()->json([
                'message' => 'OTP sudah digunakan untuk verifikasi. Silakan meminta OTP baru.',
            ], 422);
        }

        if (now()->greaterThanOrEqualTo($otpRecord->expires_at)) {
            $otpRecord->delete();

            return response()->json([
                'message' => 'OTP sudah kedaluwarsa. Silakan meminta OTP baru.',
            ], 422);
        }

        if ($otpRecord->attempts >= 5) {
            $otpRecord->delete();

            return response()->json([
                'message' => 'Batas percobaan OTP telah tercapai. Silakan meminta OTP baru.',
            ], 429);
        }

        // Periksa OTP yang dimasukkan pengguna.
        if (!Hash::check($request->input('otp'), $otpRecord->otp_hash)) {
            $otpRecord->increment('attempts');

            return response()->json([
                'message' => 'OTP yang Anda masukkan salah.',
            ], 422);
        }

        // Buat token acak setelah OTP berhasil diverifikasi.
        $verificationToken = Str::random(64);

        $otpRecord->update([
            'verified_at' => now(),
            'verification_token_hash' => Hash::make($verificationToken),
            'verification_expires_at' => now()->addMinutes(10),
        ]);

        return response()->json([
            'message' => 'OTP berhasil diverifikasi.',
            'verification_token' => $verificationToken,
        ]);
    }

    /**
     * Mengganti password setelah OTP berhasil diverifikasi.
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'method' => 'required|in:email,whatsapp',
            'verification_token' => 'required|string',
            'password' => [
                'required',
                'confirmed',
                Password::min(8),
            ],
        ]);

        $user = $request->user();
        $method = $request->input('method');

        // Ambil token verifikasi khusus perubahan password profil.
        $otpRecord = PasswordChangeOtp::where('user_id', $user->id)
            ->where('purpose', 'profile')
            ->where('method', $method)
            ->whereNotNull('verified_at')
            ->first();

        if (!$otpRecord) {
            return response()->json([
                'message' => 'Verifikasi OTP tidak ditemukan.',
            ], 422);
        }

        if (
            !$otpRecord->verification_expires_at ||
            now()->greaterThanOrEqualTo($otpRecord->verification_expires_at)
        ) {
            $otpRecord->delete();

            return response()->json([
                'message' => 'Token verifikasi telah kedaluwarsa. Silakan verifikasi OTP kembali.',
            ], 422);
        }

        $verificationToken = $request->input('verification_token');
        $storedHash = $otpRecord->verification_token_hash;

        if (
            empty($storedHash) ||
            !Hash::check($verificationToken, $storedHash)
        ) {
            return response()->json([
                'message' => 'Token verifikasi tidak valid.',
            ], 422);
        }

        // Perbarui password akun.
        $user->password = Hash::make($request->password);
        $user->save();

        // Hapus OTP dan token setelah berhasil digunakan.
        $otpRecord->delete();

        return response()->json([
            'message' => 'Password berhasil diubah.',
        ]);
    }
}
