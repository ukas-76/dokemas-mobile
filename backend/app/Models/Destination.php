<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Destination extends Model
{
    protected $fillable = [
        'category_id', 'user_id', 'name', 'slug', 'description', 'address',
        'district', 'access_directions', 'maps_url',
        'latitude', 'longitude', 'price', 'opening_hours', 'phone', 'cs_phone',
        'is_24_hours', 'thumbnail', 'rating_avg', 'rating_count', 'is_popular', 'status',
    ];

    protected $appends = [
        'thumbnail_url',
        'image',
        'image_url',
        'cover_image',
    ];

    protected function thumbnailUrl(): Attribute
    {
        return Attribute::get(function (mixed $value, array $attributes) {
            $thumb = $attributes['thumbnail'] ?? null;
            if (empty($thumb)) {
                return $this->relationLoaded('images')
                    ? $this->images->first()?->image_url
                    : $this->images()->first()?->image_url;
            }
            if (str_starts_with($thumb, 'http://') || str_starts_with($thumb, 'https://')) {
                return $thumb;
            }
            return Storage::disk('public')->url($thumb);
        });
    }

    protected function image(): Attribute
    {
        return Attribute::get(fn () => $this->thumbnail_url);
    }

    protected function imageUrl(): Attribute
    {
        return Attribute::get(fn () => $this->thumbnail_url);
    }

    protected function coverImage(): Attribute
    {
        return Attribute::get(fn () => $this->thumbnail_url);
    }

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'price' => 'float',
            'rating_avg' => 'float',
            'is_popular' => 'boolean',
            'is_24_hours' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(DestinationImage::class);
    }

    public function facilities(): BelongsToMany
    {
        return $this->belongsToMany(Facility::class, 'destination_facilities')->withTimestamps();
    }

    public function wishlists(): HasMany
    {
        return $this->hasMany(Wishlist::class);
    }

    public function recalcRating(): void
    {
        $publicReviews = $this->reviews()->where('status', 'public');
        $this->rating_avg = (float) round($publicReviews->avg('rating') ?? 0, 2);
        $this->rating_count = $publicReviews->count();
        $this->save();
    }
}