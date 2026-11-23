<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\DestinationImage;
use App\Models\MitraProfile;
use App\Models\User;
use App\Services\ImageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class MitraRegistrationController extends Controller
{
    public function __construct(private ImageService $images) {}

    /**
     * Pendaftaran Kemitraan DOKEMAS (Form 4 Langkah dari Website).
     */
    public function register(Request $request): JsonResponse
    {
        $existingUser = auth('sanctum')->user() ?? User::where('email', $request->input('email'))->first();
        $ignoreUserId = $existingUser ? $existingUser->id : 'NULL';

        // Jika user yang sudah terdaftar adalah mitra atau admin, dan sudah punya profil mitra
        if ($existingUser && $existingUser->mitraProfile) {
            return response()->json([
                'message' => 'Akun dengan email ini sudah terdaftar sebagai mitra dan memiliki profil kemitraan.',
            ], 422);
        }

        $validated = $request->validate([
            // Step 1: Informasi Akun & Penanggung Jawab
            'name' => ['required', 'string', 'max:255'],
            'nik' => ['required', 'string', 'max:20'],
            'entity_type' => ['required', 'string', 'max:100'],
            'position' => ['required', 'string', 'max:100'],
            'phone' => ['required', 'string', 'max:25'],
            'email' => ['required', 'string', 'email', 'max:255', "unique:users,email,{$ignoreUserId}"],
            'password' => [$existingUser ? 'nullable' : 'required', 'string', 'min:8', 'confirmed'],

            // Step 2: Profil Destinasi
            'destination_name' => ['required', 'string', 'max:255'],
            'category_id' => ['required', 'exists:categories,id'],
            'price' => ['nullable', 'numeric', 'min:0'],
            'opening_hours' => ['nullable', 'string', 'max:100'],
            'is_24_hours' => ['nullable', 'boolean'],
            'district' => ['required', 'string', 'max:100'],
            'maps_url' => ['nullable', 'string', 'max:500'],
            'address' => ['required', 'string'],
            'access_directions' => ['nullable', 'string'],
            'cs_phone' => ['required', 'string', 'max:25'],
            'photos' => ['nullable', 'array', 'min:1'],
            'photos.*' => ['file', 'mimes:jpeg,png,jpg,webp', 'max:5120'], // Max 5MB per file

            // Step 3: Legalitas & Rekening
            'nib' => ['required', 'string', 'max:50'],
            'npwp' => ['nullable', 'string', 'max:50'],
            'environmental_permit' => ['nullable', 'string', 'max:100'],
            'land_status' => ['nullable', 'string', 'max:100'],
            'file_nib' => ['required', 'file', 'mimes:pdf,jpeg,png,jpg', 'max:10240'], // Max 10MB
            'file_supporting' => ['nullable', 'file', 'mimes:pdf,jpeg,png,jpg', 'max:10240'],
            'bank_name' => ['required', 'string', 'max:100'],
            'bank_account_number' => ['required', 'string', 'max:50'],
            'bank_account_holder' => ['required', 'string', 'max:150'],
        ]);

        return DB::transaction(function () use ($request, $validated, $existingUser) {
            // 1. Buat User Mitra Baru atau Upgrade Akun User yang Sudah Ada
            if ($existingUser) {
                $user = $existingUser;
                $userUpdate = [
                    'name' => $validated['name'],
                    'phone' => $validated['phone'],
                    'role' => 'mitra',
                ];
                if (! empty($validated['password'])) {
                    $userUpdate['password'] = Hash::make($validated['password']);
                }
                $user->update($userUpdate);
            } else {
                $user = User::create([
                    'name' => $validated['name'],
                    'email' => $validated['email'],
                    'phone' => $validated['phone'],
                    'password' => Hash::make($validated['password']),
                    'role' => 'mitra',
                ]);
            }

            // 2. Simpan Berkas Legalitas
            $nibPath = null;
            if ($request->hasFile('file_nib')) {
                $nibPath = $request->file('file_nib')->store('documents/mitra/nib', 'public');
            }

            $supportingPath = null;
            if ($request->hasFile('file_supporting')) {
                $supportingPath = $request->file('file_supporting')->store('documents/mitra/supporting', 'public');
            }

            // 3. Buat Profil Mitra
            $mitraProfile = MitraProfile::create([
                'user_id' => $user->id,
                'nik' => $validated['nik'],
                'entity_type' => $validated['entity_type'],
                'position' => $validated['position'],
                'nib' => $validated['nib'],
                'npwp' => $validated['npwp'] ?? null,
                'environmental_permit' => $validated['environmental_permit'] ?? null,
                'land_status' => $validated['land_status'] ?? null,
                'file_nib' => $nibPath,
                'file_supporting' => $supportingPath,
                'bank_name' => $validated['bank_name'],
                'bank_account_number' => $validated['bank_account_number'],
                'bank_account_holder' => $validated['bank_account_holder'],
                'verification_status' => 'pending',
            ]);

            // 4. Buat Destinasi dengan Status Pending
            $slug = Str::slug($validated['destination_name']) . '-' . Str::random(5);
            $destination = Destination::create([
                'user_id' => $user->id,
                'category_id' => $validated['category_id'],
                'name' => $validated['destination_name'],
                'slug' => $slug,
                'description' => $validated['destination_name'] . ' - Destinasi mitra resmi DOKEMAS Banyumas.',
                'address' => $validated['address'],
                'district' => $validated['district'],
                'access_directions' => $validated['access_directions'] ?? null,
                'maps_url' => $validated['maps_url'] ?? null,
                'phone' => $validated['phone'],
                'cs_phone' => $validated['cs_phone'],
                'price' => $validated['price'] ?? 0,
                'opening_hours' => $validated['opening_hours'] ?? null,
                'is_24_hours' => $request->boolean('is_24_hours'),
                'status' => 'pending', // menunggu verifikasi kurator Dinporabudpar
            ]);

            // 5. Simpan Galeri Foto Destinasi
            if ($request->hasFile('photos')) {
                $first = true;
                foreach ($request->file('photos') as $photo) {
                    $path = $this->images->storeAsWebp($photo, 'destinations');
                    DestinationImage::create([
                        'destination_id' => $destination->id,
                        'image' => $path,
                    ]);

                    // Jadikan foto pertama sebagai thumbnail cover
                    if ($first) {
                        $destination->update(['thumbnail' => $path]);
                        $first = false;
                    }
                }
            }

            // Buat token Sanctum agar web mitra bisa langsung login ke dashboard portalnya
            $token = $user->createToken('mitra-web-auth')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Pendaftaran mitra berhasil dikirim. Menunggu verifikasi tim Dinporabudpar Banyumas.',
                'data' => [
                    'user' => $user,
                    'mitra_profile' => $mitraProfile,
                    'destination' => $destination->load('images'),
                    'token' => $token,
                ],
            ], 201);
        });
    }

    /**
     * Cek status pendaftaran mitra (untuk halaman dashboard / profil mitra).
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user->isMitra()) {
            return response()->json(['message' => 'Bukan akun mitra.'], 403);
        }

        $profile = $user->mitraProfile;
        $destinations = $user->destinations()->with('images')->get();

        return response()->json([
            'user' => $user,
            'mitra_profile' => $profile,
            'destinations' => $destinations,
        ]);
    }
}

