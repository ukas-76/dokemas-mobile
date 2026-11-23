<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('destinations', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('category_id')->constrained('users')->nullOnDelete();
            $table->string('district')->nullable()->after('address'); // Kecamatan di Kab. Banyumas
            $table->text('access_directions')->nullable()->after('district'); // Petunjuk arah akses kendaraan
            $table->string('maps_url')->nullable()->after('access_directions'); // Link Google Maps
            $table->string('cs_phone')->nullable()->after('phone'); // No WA CS Resmi
            $table->boolean('is_24_hours')->default(false)->after('opening_hours');
            $table->enum('status', ['draft', 'pending', 'published', 'archived'])->default('published')->after('is_popular');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('destinations', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn([
                'user_id',
                'district',
                'access_directions',
                'maps_url',
                'cs_phone',
                'is_24_hours',
                'status',
            ]);
        });
    }
};

