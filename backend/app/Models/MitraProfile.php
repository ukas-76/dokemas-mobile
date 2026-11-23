<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class MitraProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'nik',
        'entity_type',
        'position',
        'nib',
        'npwp',
        'environmental_permit',
        'land_status',
        'file_nib',
        'file_supporting',
        'bank_name',
        'bank_account_number',
        'bank_account_holder',
        'verification_status',
        'rejection_reason',
        'verified_at',
    ];

    protected $appends = [
        'file_nib_url',
        'file_supporting_url',
    ];

    protected function casts(): array
    {
        return [
            'verified_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getFileNibUrlAttribute(): ?string
    {
        return $this->file_nib ? Storage::disk('public')->url($this->file_nib) : null;
    }

    public function getFileSupportingUrlAttribute(): ?string
    {
        return $this->file_supporting ? Storage::disk('public')->url($this->file_supporting) : null;
    }
}

