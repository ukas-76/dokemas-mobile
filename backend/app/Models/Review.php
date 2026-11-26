<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    protected $fillable = [
        'user_id', 'destination_id', 'rating', 'comment',
        'reply', 'replied_at', 'status', 'flag_count', 'flag_reason',
    ];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'flag_count' => 'integer',
            'replied_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function destination(): BelongsTo
    {
        return $this->belongsTo(Destination::class);
    }
}