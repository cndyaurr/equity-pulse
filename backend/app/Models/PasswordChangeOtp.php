<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PasswordChangeOtp extends Model
{
    protected $fillable = [
        'user_id',
        'method',
        'otp_hash',
        'expires_at',
        'attempts',
        'verified_at',
        'verification_token_hash',
        'verification_expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'verified_at' => 'datetime',
        'verification_expires_at' => 'datetime',
    ];
}