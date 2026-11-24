<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    // ==========================================
    // HELPER NOMOR TELEPON
    // ==========================================

    private function normalizePhone(string $phone): string
    {
        $phone = preg_replace('/[\s\-()]/', '', $phone);

        // 081234567890 menjadi +6281234567890
        return '+62' . substr($phone, 1);
    }

    private function displayPhone(?string $phone): ?string
    {
        if (!$phone) {
            return null;
        }

        // +6281234567890 menjadi 081234567890
        if (str_starts_with($phone, '+62')) {
            return '0' . substr($phone, 3);
        }

        return $phone;
    }

    // ==========================================
    // REGISTER
    // ==========================================

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email',
            ],
            'phone' => [
                'required',
                'string',
                'regex:/^08[0-9]{8,11}$/',
            ],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
            ],
            'work_location' => [
                'required',
                'string',
                'max:255',
            ],
        ], [
            'phone.required' => 'Nomor HP wajib diisi.',
            'phone.regex' => 'Nomor HP harus menggunakan format 08xxxxxxxxxx.',
        ]);

        $normalizedPhone = $this->normalizePhone($validated['phone']);

        // Cek nomor HP unik setelah dinormalisasi
        if (User::where('phone', $normalizedPhone)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Nomor HP sudah terdaftar.',
            ], 422);
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => strtolower($validated['email']),
            'phone' => $normalizedPhone,
            'password' => Hash::make($validated['password']),
            'work_location' => $validated['work_location'],
        ]);

        event(new Registered($user));

        return response()->json([
            'success' => true,
            'message' => 'Pendaftaran berhasil. Silakan cek email untuk verifikasi akun.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $this->displayPhone($user->phone),
                'email_verified_at' => $user->email_verified_at,
                'work_location' => $user->work_location,
            ],
        ], 201);
    }

    // ==========================================
    // RESEND VERIFICATION EMAIL
    // ==========================================

    public function resendVerificationEmail(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where(
            'email',
            strtolower($request->email)
        )->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Akun tidak ditemukan.',
            ], 404);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json([
                'success' => true,
                'message' => 'Email sudah terverifikasi.',
            ]);
        }

        $user->sendEmailVerificationNotification();

        return response()->json([
            'success' => true,
            'message' => 'Email verifikasi berhasil dikirim ulang.',
        ]);
    }

    // ==========================================
    // LOGIN EMAIL / NOMOR HP
    // ==========================================

    public function login(Request $request)
    {
        $validated = $request->validate([
            'login' => [
                'required_without:email',
                'nullable',
                'string',
                'max:255',
            ],
            'email' => [
                'required_without:login',
                'nullable',
                'string',
                'max:255',
            ],
            'password' => ['required', 'string'],
        ]);

        $identifier = trim(
            $validated['login'] ?? $validated['email']
        );

        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $user = User::where(
                'email',
                strtolower($identifier)
            )->first();
        } else {
            if (!preg_match('/^08[0-9]{8,11}$/', $identifier)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Masukkan email atau nomor HP dengan format 08 yang benar.',
                ], 422);
            }

            $user = User::where(
                'phone',
                $this->normalizePhone($identifier)
            )->first();
        }

        if (
            !$user ||
            !Hash::check($validated['password'], $user->password)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Email/nomor HP atau kata sandi salah.',
            ], 401);
        }

        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Verifikasi email terlebih dahulu.',
            ], 403);
        }

        $token = $user->createToken('flutter-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $this->displayPhone($user->phone),
                'work_location' => $user->work_location,
            ],
        ]);
    }

    // ==========================================
    // PROFILE
    // ==========================================

    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $this->displayPhone($user->phone),
                'work_location' => $user->work_location,
            ],
        ]);
    }

    // ==========================================
    // UPDATE PROFILE
    // ==========================================

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'work_location' => ['required', 'string', 'max:255'],
            'phone' => [
                'sometimes',
                'required',
                'string',
                'regex:/^08[0-9]{8,11}$/',
            ],
        ], [
            'phone.required' => 'Nomor HP wajib diisi.',
            'phone.regex' => 'Nomor HP harus menggunakan format 08xxxxxxxxxx.',
        ]);

        if (isset($validated['phone'])) {
            $normalizedPhone = $this->normalizePhone(
                $validated['phone']
            );

            $phoneExists = User::where('phone', $normalizedPhone)
                ->where('id', '!=', $user->id)
                ->exists();

            if ($phoneExists) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nomor HP sudah digunakan akun lain.',
                ], 422);
            }

            $user->phone = $normalizedPhone;
        }

        $user->name = $validated['name'];
        $user->work_location = $validated['work_location'];
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $this->displayPhone($user->phone),
                'work_location' => $user->work_location,
            ],
        ]);
    }

    // ==========================================
    // CHANGE PASSWORD
    // ==========================================

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
            ],
        ], [
            'current_password.required' => 'Kata sandi saat ini wajib diisi.',
            'password.required' => 'Kata sandi baru wajib diisi.',
            'password.min' => 'Kata sandi baru minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi kata sandi baru tidak cocok.',
        ]);

        $user = $request->user();

        if (!Hash::check(
            $validated['current_password'],
            $user->password
        )) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi saat ini tidak sesuai.',
            ], 422);
        }

        if (Hash::check(
            $validated['password'],
            $user->password
        )) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi baru harus berbeda dari kata sandi saat ini.',
            ], 422);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi berhasil diperbarui.',
        ], 200);
    }
}
