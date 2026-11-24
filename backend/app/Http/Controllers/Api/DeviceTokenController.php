<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    /**
     * Mendaftarkan atau memperbarui token perangkat.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'device_name' => ['nullable', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'max:30'],
        ]);

        $user = $request->user();

        // Jika token sudah terdaftar pada perangkat lain,
        // pindahkan kepemilikannya ke pengguna yang sedang login.
        $deviceToken = DeviceToken::updateOrCreate(
            ['token' => $validated['token']],
            [
                'user_id' => $user->id,
                'device_name' => $validated['device_name'] ?? null,
                'platform' => $validated['platform'] ?? 'android',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Token perangkat berhasil didaftarkan.',
        ]);
    }

    /**
     * Menghapus token perangkat saat logout.
     */
    public function destroy(Request $request)
    {
        $validated = $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        DeviceToken::where('user_id', $request->user()->id)
            ->where('token', $validated['token'])
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Token perangkat berhasil dihapus.',
        ]);
    }
}
