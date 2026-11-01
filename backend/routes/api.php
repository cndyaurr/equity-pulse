<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GoldPriceController;
use App\Http\Controllers\Api\PivotPointController;
use Illuminate\Support\Facades\URL;
use App\Models\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Support\Facades\Password;
use App\Http\Controllers\Api\NewsController;

Route::get('/gold-prices', [GoldPriceController::class, 'index']);
Route::get('/gold-prices/latest', [GoldPriceController::class, 'latest']);
Route::get('/news', [NewsController::class, 'index']);
Route::get('/pivot-points', [PivotPointController::class, 'index']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
});
// Verifikasi email
Route::get('/email/verify/{id}/{hash}', function (Request $request, $id, $hash) {
    if (! URL::hasValidSignature($request)) {
        return response()->json([
            'success' => false,
            'message' => 'Link verifikasi tidak valid atau sudah kedaluwarsa.',
        ], 403);
    }

    $user = User::findOrFail($id);

    if (! hash_equals(sha1($user->getEmailForVerification()), $hash)) {
        return response()->json([
            'success' => false,
            'message' => 'Link verifikasi tidak cocok dengan email akun.',
        ], 403);
    }

    if (! $user->hasVerifiedEmail()) {
        $user->markEmailAsVerified();
        event(new Verified($user));
    }

    return response()->json([
        'success' => true,
        'message' => 'Email berhasil diverifikasi. Silakan login.',
    ]);
})->name('verification.verify');

Route::post(
    '/email/resend-verification',
    [AuthController::class, 'resendVerificationEmail']
)->middleware('throttle:6,1');


Route::post('/forgot-password', function (Request $request) {
    $request->validate([
        'email' => ['required', 'email'],
    ]);

    $status = Password::sendResetLink(
        $request->only('email')
    );

    if ($status === Password::RESET_LINK_SENT) {
        return response()->json([
            'message' => 'Link reset sandi berhasil dikirim ke email.',
        ]);
    }

    return response()->json([
        'message' => 'Email tidak ditemukan atau link reset gagal dikirim.',
    ], 422);
});

Route::post('/reset-password', function (Request $request) {
    $request->validate([
        'token' => ['required'],
        'email' => ['required', 'email'],
        'password' => ['required', 'min:8', 'confirmed'],
    ]);

    $status = Password::reset(
        $request->only('email', 'password', 'password_confirmation', 'token'),
        function ($user, $password) {
            $user->forceFill([
                'password' => \Illuminate\Support\Facades\Hash::make($password),
            ])->save();
        }
    );

    if ($status === Password::PASSWORD_RESET) {
        return response()->json([
            'message' => 'Sandi berhasil diubah.',
        ]);
    }

    return response()->json([
        'message' => 'Token tidak valid atau sudah kedaluwarsa.',
    ], 422);
});
