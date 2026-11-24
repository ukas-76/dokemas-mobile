<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class DestinationImage extends Model
{
    protected $fillable = ['destination_id', 'image_path', 'caption'];

    protected $appends = ['image_url', 'image', 'url'];

    protected function imageUrl(): Attribute
    {
        return Attribute::get(function (mixed $value, array $attributes) {
            if (empty($attributes['image_path'])) {
                return null;
            }
            $path = $attributes['image_path'];
            if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
                return $path;
            }
            return Storage::disk('public')->url($path);
        });
    }

    protected function image(): Attribute
    {
        return Attribute::get(fn () => $this->image_url);
    }

    protected function url(): Attribute
    {
        return Attribute::get(fn () => $this->image_url);
    }

    public function destination(): BelongsTo
    {
        return $this->belongsTo(Destination::class);
    }
}