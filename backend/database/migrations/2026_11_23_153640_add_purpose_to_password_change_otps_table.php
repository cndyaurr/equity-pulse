
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('password_change_otps', function (Blueprint $table) {
            $table->string('purpose', 30)
                ->default('profile')
                ->after('method');

            $table->index(['user_id', 'purpose', 'method']);
        });
    }

    public function down(): void
    {
        Schema::table('password_change_otps', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'purpose', 'method']);
            $table->dropColumn('purpose');
        });
    }
};
