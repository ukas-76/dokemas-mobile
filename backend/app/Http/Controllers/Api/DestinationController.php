<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\DestinationImage;
use App\Services\ImageService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DestinationController extends Controller
{
    public function __construct(private ImageService $images) {}

    public function index(Request $request)
    {
        $user = auth('sanctum')->user();
        $isAdmin = $user && in_array($user->role, ['admin', 'super_admin', 'superadmin']);

        $query = Destination::query()
            ->with(['category', 'images', 'facilities', 'user:id,name,email,phone,role'])
            ->withCount('reviews');

        $status = $request->query('status');
        if ($isAdmin && $status) {
            if ($status !== 'all') {
                $query->where('status', $status);
            }
        } elseif ($isAdmin && $request->has('status')) {
            // Admin meminta seluruh destinasi tanpa filter status
        } else {
            // Publik/tamu default hanya melihat destinasi published
            $query->where('status', 'published');
        }

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('address', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($categoryId = $request->query('category_id')) {
            $query->where('category_id', $categoryId);
        }

        if (! is_null($request->query('min_price'))) {
            $query->where('price', '>=', (float) $request->query('min_price'));
        }
        if (! is_null($request->query('max_price'))) {
            $query->where('price', '<=', (float) $request->query('max_price'));
        }

        if ($request->boolean('popular')) {
            $query->where('is_popular', true);
        }

        $sort = $request->query('sort', 'latest');
        match ($sort) {
            'rating' => $query->orderByDesc('rating_avg'),
            'price_asc' => $query->orderBy('price'),
            'price_desc' => $query->orderByDesc('price'),
            'name' => $query->orderBy('name'),
            default => $query->latest(),
        };

        return $query->paginate($request->integer('per_page', 15));
    }

    public function store(Request $request)
    {
        $data = $this->validateData($request);
        unset($data['thumbnail'], $data['images']);
        $data['slug'] = Str::slug($data['name']).'-'.Str::random(5);

        if ($request->hasFile('thumbnail')) {
            $data['thumbnail'] = $this->images->storeAsWebp($request->file('thumbnail'), 'destinations');
        } elseif ($request->filled('thumbnail') && is_string($request->input('thumbnail'))) {
            $data['thumbnail'] = $request->input('thumbnail');
        }

        $facilities = $request->input('facility_ids', []);
        $destination = Destination::create($data);

        $this->storeGallery($request, $destination);
        if ($facilities) {
            $destination->facilities()->sync($facilities);
        }

        return response()->json($destination->load(['category', 'facilities', 'images']), 201);
    }

    public function show(Destination $destination)
    {
        if ($destination->status !== 'published') {
            $user = auth('sanctum')->user();
            if (! $user || ($user->role !== 'admin' && $user->id !== $destination->user_id)) {
                return response()->json([
                    'message' => 'Destinasi ini belum dipublikasikan atau masih dalam tahap kurasi.',
                ], 404);
            }
        }

        return $destination->load([
            'category',
            'facilities',
            'images',
            'reviews.user:id,name,avatar',
        ]);
    }

    /**
     * Dapatkan daftar penginapan / hotel terdekat dari destinasi ini.
     * Radius maksimal 2.0 km sesuai spesifikasi.
     */
    public function nearbyAccommodations(Request $request, Destination $destination)
    {
        $lat = $destination->latitude;
        $lng = $destination->longitude;

        if (is_null($lat) || is_null($lng)) {
            return response()->json([
                'destination_id' => $destination->id,
                'radius_km' => 2.0,
                'data' => [],
            ]);
        }

        $radius = min((float) $request->query('radius', 2.0), 2.0);

        // Haversine formula dalam kilometer
        $haversine = "(6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude))))))";

        $accommodations = Destination::query()
            ->select('destinations.*')
            ->selectRaw("{$haversine} AS distance_km", [$lat, $lng, $lat])
            ->where('status', 'published')
            ->where('id', '!=', $destination->id)
            ->whereHas('category', function ($q) {
                $q->where('slug', 'like', '%hotel%')
                  ->orWhere('slug', 'like', '%penginapan%');
            })
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->having('distance_km', '<=', $radius)
            ->orderBy('distance_km', 'asc')
            ->limit(10)
            ->get();

        $data = $accommodations->map(function ($item) {
            $dist = round((float) $item->distance_km, 2);
            $distText = $dist < 1.0 ? round($dist * 1000) . ' m' : $dist . ' km';

            return [
                'id' => $item->id,
                'name' => $item->name,
                'slug' => $item->slug,
                'thumbnail_url' => $item->thumbnail_url,
                'price' => $item->price,
                'rating_avg' => $item->rating_avg,
                'rating_count' => $item->rating_count,
                'district' => $item->district,
                'address' => $item->address,
                'distance_km' => $dist,
                'distance_text' => $distText,
            ];
        });

        return response()->json([
            'destination_id' => $destination->id,
            'radius_km' => $radius,
            'data' => $data,
        ]);
    }

    /**
     * Kurasi status destinasi oleh admin (published, pending, draft, archived).
     */
    public function updateStatus(Request $request, Destination $destination)
    {
        $validated = $request->validate([
            'status' => ['required', 'string', 'in:draft,pending,published,archived'],
        ]);

        $destination->update(['status' => $validated['status']]);

        return response()->json([
            'message' => "Status destinasi '{$destination->name}' berhasil diubah menjadi {$destination->status}.",
            'data' => $destination->fresh()->load(['category', 'facilities', 'images']),
        ]);
    }

    public function update(Request $request, Destination $destination)
    {
        $data = $this->validateData($request, false);
        unset($data['thumbnail'], $data['images']);
        if (isset($data['name'])) {
            $data['slug'] = Str::slug($data['name']).'-'.Str::random(5);
        }

        if ($request->hasFile('thumbnail')) {
            $this->images->delete($destination->thumbnail);
            $data['thumbnail'] = $this->images->storeAsWebp($request->file('thumbnail'), 'destinations');
        } elseif ($request->filled('thumbnail') && is_string($request->input('thumbnail'))) {
            $data['thumbnail'] = $request->input('thumbnail');
        }

        $destination->update($data);
        $this->storeGallery($request, $destination);
        if ($request->has('facility_ids')) {
            $destination->facilities()->sync($request->input('facility_ids', []));
        }

        return response()->json($destination->load(['category', 'facilities', 'images']));
    }

    public function destroy(Destination $destination)
    {
        // hapus file fisik thumbnail + galeri
        $this->images->delete($destination->thumbnail);
        foreach ($destination->images as $image) {
            $this->images->delete($image->image_path);
        }

        $destination->delete();

        return response()->json(['message' => 'Destination deleted.']);
    }

    /**
     * Upload satu/banyak foto galeri (field: images[] atau image).
     */
    public function uploadImages(Request $request, Destination $destination)
    {
        $request->validate([
            'images' => ['required_without:image', 'array'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'image' => ['required_without:images', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'caption' => ['nullable', 'string', 'max:255'],
        ]);

        $files = $request->file('images', []);
        if ($request->hasFile('image')) {
            $files[] = $request->file('image');
        }

        $created = [];
        foreach ($files as $file) {
            $path = $this->images->storeAsWebp($file, 'destinations');
            $created[] = $destination->images()->create([
                'image_path' => $path,
                'caption' => $request->input('caption'),
            ]);
        }

        return response()->json($created, 201);
    }

    public function deleteImage(DestinationImage $image)
    {
        $this->images->delete($image->image_path);
        $image->delete();

        return response()->json(['message' => 'Image deleted.']);
    }

    private function storeGallery(Request $request, Destination $destination): void
    {
        foreach ($request->file('images', []) as $file) {
            $path = $this->images->storeAsWebp($file, 'destinations');
            $destination->images()->create(['image_path' => $path]);
        }
    }

    private function validateData(Request $request, bool $creating = true): array
    {
        $required = $creating ? 'required' : 'sometimes';

        return $request->validate([
            'category_id' => [$required, 'exists:categories,id'],
            'name' => [$required, 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'address' => ['nullable', 'string', 'max:255'],
            'district' => ['nullable', 'string', 'max:255'],
            'access_directions' => ['nullable', 'string'],
            'maps_url' => ['nullable', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'price' => ['nullable', 'numeric', 'min:0'],
            'opening_hours' => ['nullable', 'string', 'max:255'],
            'is_24_hours' => ['nullable', 'boolean'],
            'phone' => ['nullable', 'string', 'max:30'],
            'cs_phone' => ['nullable', 'string', 'max:30'],
            'status' => ['nullable', 'string', 'in:draft,pending,published,archived'],
            'thumbnail' => ['nullable'],
            'is_popular' => ['nullable', 'boolean'],
            'facility_ids' => ['nullable', 'array'],
            'facility_ids.*' => ['integer', 'exists:facilities,id'],
            'images' => ['nullable', 'array'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
    }
}