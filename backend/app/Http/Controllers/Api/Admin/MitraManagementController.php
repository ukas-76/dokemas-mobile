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
        $profile = MitraProfile::with(['user', 'user.destinations.images', 'user.destinations.category'])
            ->where('id', $id)
            ->orWhere('user_id', $id)
            ->firstOrFail();

        return response()->json($profile);
    }

    /**
     * Setujui pendaftaran akun mitra (Verifikasi Sukses NIB & Legalitas).
     * Destinasi tempat wisata TETAP berstatus 'pending' menunggu kurasi terpisah.
     */
    public function approve(int $id): JsonResponse
    {
        $profile = MitraProfile::where('id', $id)->orWhere('user_id', $id)->first();
        if (! $profile) {
            $user = \App\Models\User::findOrFail($id);
            $profile = MitraProfile::create([
                'user_id' => $user->id,
                'entity_type' => 'Perorangan',
                'nib' => 'NIB-' . date('YmdHis'),
                'verification_status' => 'verified',
                'verified_at' => now(),
            ]);
            $user->update(['role' => 'mitra']);
        } else {
            $profile->update([
                'verification_status' => 'verified',
                'verified_at' => now(),
                'rejection_reason' => null,
            ]);
            if ($profile->user) {
                $profile->user->update(['role' => 'mitra']);
            }
        }

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
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);

        $profile = MitraProfile::where('id', $id)->orWhere('user_id', $id)->first();
        $reason = $request->input('reason', 'Dokumen atau data kemitraan belum memenuhi persyaratan verifikasi.');

        if (! $profile) {
            $user = \App\Models\User::findOrFail($id);
            $profile = MitraProfile::create([
                'user_id' => $user->id,
                'entity_type' => 'Perorangan',
                'nib' => 'NIB-' . date('YmdHis'),
                'verification_status' => 'rejected',
                'rejection_reason' => $reason,
            ]);
        } else {
            $profile->update([
                'verification_status' => 'rejected',
                'rejection_reason' => $reason,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Pendaftaran mitra ditolak dengan catatan evaluasi.',
            'data' => $profile,
        ]);
    }
}

