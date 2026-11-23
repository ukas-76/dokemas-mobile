<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\MitraProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MitraManagementController extends Controller
{
    /**
     * Tampilkan daftar pendaftaran mitra untuk kurasi admin Dinporabudpar.
     */
    public function index(Request $request): JsonResponse
    {
        $query = MitraProfile::query()->with(['user', 'user.destinations.images'])->latest();

        if ($status = $request->query('status')) {
            $query->where('verification_status', $status);
        }

        if ($search = $request->query('search')) {
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            })->orWhere('nib', 'like', "%{$search}%");
        }

        return response()->json($query->paginate($request->integer('per_page', 15)));
    }

    /**
     * Detail lengkap permohonan mitra.
     */
    public function show(int $id): JsonResponse
    {
        $profile = MitraProfile::with(['user', 'user.destinations.images', 'user.destinations.category'])->findOrFail($id);

        return response()->json($profile);
    }

    /**
     * Setujui pendaftaran akun mitra (Verifikasi Sukses NIB & Legalitas).
     * Destinasi tempat wisata TETAP berstatus 'pending' menunggu kurasi terpisah.
     */
    public function approve(int $id): JsonResponse
    {
        $profile = MitraProfile::findOrFail($id);
        $profile->update([
            'verification_status' => 'verified',
            'verified_at' => now(),
            'rejection_reason' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Akun kemitraan berhasil diverifikasi. Status destinasi tetap pending dan menunggu kurasi konten tempat wisata oleh Super Admin.',
            'data' => $profile->load(['user', 'user.destinations']),
        ]);
    }

    /**
     * Tolak pendaftaran mitra dengan alasan perbaikan.
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);

        $profile = MitraProfile::findOrFail($id);
        $profile->update([
            'verification_status' => 'rejected',
            'rejection_reason' => $request->input('reason'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pendaftaran mitra ditolak dengan catatan evaluasi.',
            'data' => $profile,
        ]);
    }
}

