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
        Schema::create('mitra_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            
            // Step 1: Data Penanggung Jawab
            $table->string('nik', 20)->nullable();
            $table->string('entity_type')->default('Perorangan'); // Perorangan, CV, PT, Koperasi, Pokdarwis, dll.
            $table->string('position')->default('Pengelola'); // Jabatan dalam pengelolaan
            
            // Step 3: Legalitas & Perizinan Berusaha
            $table->string('nib', 50)->nullable(); // Nomor Induk Berusaha OSS-RBA
            $table->string('npwp', 50)->nullable(); // NPWP
            $table->string('environmental_permit')->nullable(); // SPPL, UKL-UPL, AMDAL
            $table->string('land_status')->nullable(); // Kerjasama Perhutani, Milik Pribadi, dll.
            
            // Berkas Dokumen Persyaratan
            $table->string('file_nib')->nullable(); // Path scan berkas NIB
            $table->string('file_supporting')->nullable(); // Path dokumen pendukung opsional
            
            // Rekening Operasional & Verifikasi
            $table->string('bank_name', 100)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('bank_account_holder', 150)->nullable();
            
            // Status Kurasi / Verifikasi oleh Dinporabudpar
            $table->enum('verification_status', ['pending', 'verified', 'rejected'])->default('pending');
            $table->text('rejection_reason')->nullable();
            $table->timestamp('verified_at')->nullable();
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mitra_profiles');
    }
};

