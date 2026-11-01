<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'work_location' => ['required', 'string', 'max:255'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => strtolower($validated['email']),
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
                'email_verified_at' => $user->email_verified_at,
                'work_location' => $user->work_location,
            ],
        ], 201);
    }

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
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau kata sandi salah.',
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
                'work_location' => $user->work_location,
            ],
        ]);
    }
    public function profile(Request $request)
{
    $user = $request->user();

    return response()->json([
        'success' => true,
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'work_location' => $user->work_location,
        ],
    ]);
}

public function updateProfile(Request $request)
{
    $validated = $request->validate([
        'name' => ['required', 'string', 'max:255'],
        'work_location' => ['required', 'string', 'max:255'],
    ]);

    $user = $request->user();

    $user->update([
        'name' => $validated['name'],
        'work_location' => $validated['work_location'],
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Profil berhasil diperbarui.',
        'user' => [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'work_location' => $user->work_location,
        ],
    ]);
}
}
