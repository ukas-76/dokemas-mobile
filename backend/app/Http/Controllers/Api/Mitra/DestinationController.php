<?php

namespace App\Http\Controllers\Api\Mitra;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\DestinationImage;
use App\Services\ImageService;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DestinationController extends Controller
{
    public function __construct(private ImageService $images) {}

    /**
     * Menampilkan daftar destinasi yang dikelola oleh mitra yang sedang login.
     */
    public function index(Request $request)
    {
        $this->ensureMitra($request);

        $destinations = Destination::where('user_id', $request->user()->id)
            ->with(['category', 'images', 'facilities'])
            ->withCount('reviews')
            ->latest()
            ->paginate($request->integer('per_page', 15));

        return response()->json($destinations);
    }

    /**
     * Mengajukan destinasi wisata baru oleh mitra.
     * Status otomatis dikunci menjadi 'pending' dan user_id di-bind ke mitra.
     * Aturan: 1 Mitra = 1 Destinasi.
     */
    public function store(Request $request)
    {
        $this->ensureMitra($request);

        // Kunci validasi 1 Mitra = 1 Destinasi
        $hasDestination = Destination::where('user_id', $request->user()->id)->exists();
        if ($hasDestination && $request->user()->role !== 'admin') {
            return response()->json([
                'message' => 'Setiap akun mitra hanya diizinkan mengelola 1 destinasi wisata. Anda dapat memperbarui data destinasi yang sudah ada.',
            ], 422);
        }

        $validated = $request->validate([
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'address' => ['required', 'string', 'max:255'],
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
            'thumbnail' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'facility_ids' => ['nullable', 'array'],
            'facility_ids.*' => ['integer', 'exists:facilities,id'],
            'images' => ['nullable', 'array'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        unset($validated['thumbnail'], $validated['images']);

        // Set atribut wajib sistem
        $validated['user_id'] = $request->user()->id;
        $validated['status'] = 'pending'; // Otomatis pending, menunggu kurasi Dinporabudpar
        $validated['slug'] = Str::slug($validated['name']).'-'.Str::random(5);

        // Upload thumbnail jika ada
        if ($request->hasFile('thumbnail')) {
            $validated['thumbnail'] = $this->images->storeAsWebp($request->file('thumbnail'), 'destinations');
        }

        $destination = Destination::create($validated);

        // Upload galeri foto jika ada
        foreach ($request->file('images', []) as $file) {
            $path = $this->images->storeAsWebp($file, 'destinations');
            $destination->images()->create(['image_path' => $path]);
        }

        // Sinkronisasi fasilitas jika ada
        if (! empty($validated['facility_ids'])) {
            $destination->facilities()->sync($validated['facility_ids']);
        }

        return response()->json([
            'message' => 'Pengajuan destinasi baru berhasil dikirim dan menunggu verifikasi (kurasi) admin.',
            'destination' => $destination->fresh()->load(['category', 'facilities', 'images']),
        ], 201);
    }

    /**
     * Menampilkan detail satu destinasi milik mitra.
     */
    public function show(Request $request, Destination $destination)
    {
        $this->ensureMitra($request);

        if ($destination->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Anda tidak memiliki hak akses untuk destinasi ini.'], 403);
        }

        return response()->json($destination->load(['category', 'facilities', 'images']));
    }

    /**
     * Memperbarui data destinasi yang sudah dimiliki oleh mitra.
     */
    public function update(Request $request, Destination $destination)
    {
        $this->ensureMitra($request);

        if ($destination->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Anda tidak memiliki hak akses untuk destinasi ini.'], 403);
        }

        $validated = $request->validate([
            'category_id' => ['sometimes', 'integer', 'exists:categories,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'address' => ['sometimes', 'string', 'max:255'],
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
            'thumbnail' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'facility_ids' => ['nullable', 'array'],
            'facility_ids.*' => ['integer', 'exists:facilities,id'],
        ]);

        unset($validated['thumbnail']);

        if (isset($validated['name'])) {
            $validated['slug'] = Str::slug($validated['name']).'-'.Str::random(5);
        }

        // Jika data diedit oleh mitra, kembalikan status ke 'pending' untuk kurasi ulang
        if ($request->user()->role !== 'admin') {
            $validated['status'] = 'pending';
        }

        if ($request->hasFile('thumbnail')) {
            $this->images->delete($destination->thumbnail);
            $validated['thumbnail'] = $this->images->storeAsWebp($request->file('thumbnail'), 'destinations');
        }

        $destination->update($validated);

        if ($request->has('facility_ids')) {
            $destination->facilities()->sync($request->input('facility_ids', []));
        }

        return response()->json([
            'message' => 'Data destinasi berhasil diperbarui dan diajukan untuk kurasi.',
            'destination' => $destination->fresh()->load(['category', 'facilities', 'images']),
        ]);
    }

    /**
     * Upload satu atau banyak foto galeri untuk destinasi mitra.
     */
    public function uploadImages(Request $request, Destination $destination)
    {
        $this->ensureMitra($request);

        if ($destination->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Anda tidak memiliki hak akses untuk destinasi ini.'], 403);
        }

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
            $img = $destination->images()->create([
                'image_path' => $path,
                'caption' => $request->input('caption'),
            ]);
            $created[] = $img;
        }

        // Jika belum memiliki thumbnail, otomatis jadikan foto pertama yang diunggah sebagai cover
        if (empty($destination->thumbnail) && !empty($created)) {
            $destination->update(['thumbnail' => $created[0]->image_path]);
        }

        return response()->json([
            'message' => count($created).' foto berhasil ditambahkan ke galeri destinasi.',
            'images' => $destination->fresh()->images,
        ], 201);
    }

    /**
     * Hapus foto galeri destinasi mitra.
     */
    public function deleteImage(Request $request, Destination $destination, DestinationImage $image)
    {
        $this->ensureMitra($request);

        if ($destination->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Anda tidak memiliki hak akses untuk destinasi ini.'], 403);
        }

        if ($image->destination_id !== $destination->id) {
            return response()->json(['message' => 'Foto tidak terkait dengan destinasi ini.'], 404);
        }

        $this->images->delete($image->image_path);
        $image->delete();

        return response()->json([
            'message' => 'Foto galeri berhasil dihapus.',
            'images' => $destination->fresh()->images,
        ]);
    }

    /**
     * Jadikan salah satu foto galeri sebagai cover utama destinasi.
     */
    public function setCover(Request $request, Destination $destination)
    {
        $this->ensureMitra($request);

        if ($destination->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Anda tidak memiliki hak akses untuk destinasi ini.'], 403);
        }

        $request->validate([
            'image_id' => ['required', 'integer', 'exists:destination_images,id'],
        ]);

        $img = DestinationImage::where('id', $request->image_id)
            ->where('destination_id', $destination->id)
            ->firstOrFail();

        $destination->update(['thumbnail' => $img->image_path]);

        return response()->json([
            'message' => 'Foto cover utama berhasil diperbarui.',
            'destination' => $destination->fresh()->load(['category', 'facilities', 'images']),
        ]);
    }

    /**
     * Memastikan user yang mengakses memiliki role mitra atau admin.
     */
    private function ensureMitra(Request $request): void
    {
        if (! in_array($request->user()->role, ['mitra', 'admin'])) {
            abort(403, 'Akses terbatas hanya untuk akun Mitra Wisata terverifikasi.');
        }
    }
}
