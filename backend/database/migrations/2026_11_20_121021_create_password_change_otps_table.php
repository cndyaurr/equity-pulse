<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('password_change_otps', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('method', 20); // email atau whatsapp
            $table->string('otp_hash');
            $table->timestamp('expires_at');
            $table->unsignedTinyInteger('attempts')->default(0);

            $table->timestamp('verified_at')->nullable();
            $table->string('verification_token_hash')->nullable();
            $table->timestamp('verification_expires_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'method']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_change_otps');
    }
};