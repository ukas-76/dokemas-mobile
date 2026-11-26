<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Destination;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index(Request $request, Destination $destination)
    {
        $userId = auth('sanctum')->id();

        return $destination->reviews()
            ->with('user:id,name,avatar')
            ->where(function ($query) use ($userId) {
                $query->where('status', 'public');
                if ($userId) {
                    $query->orWhere('user_id', $userId);
                }
            })
            ->latest()
            ->get();
    }

    public function myReviews(Request $request)
    {
        return $request->user()->reviews()
            ->with('destination:id,name,thumbnail')
            ->latest()
            ->get();
    }

    public function store(Request $request, Destination $destination)
    {
        $data = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string'],
        ]);

        $review = Review::updateOrCreate(
            ['user_id' => $request->user()->id, 'destination_id' => $destination->id],
            [
                'rating' => $data['rating'], 
                'comment' => $data['comment'] ?? null,
                'status' => 'public', // Otomatis publik agar langsung tayang untuk wisatawan
            ],
        );

        $destination->recalcRating();

        return response()->json($review->load('user:id,name,avatar'), 201);
    }

    public function update(Request $request, Review $review)
    {
        $this->authorizeOwner($request, $review);

        $data = $request->validate([
            'rating' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string'],
        ]);
        
        $data['status'] = 'public';

        $review->update($data);
        $review->destination->recalcRating();

        return response()->json($review->load('user:id,name,avatar'));
    }

    /**
     * Balas ulasan oleh mitra pengelola destinasi atau admin.
     */
    public function reply(Request $request, Review $review)
    {
        $user = $request->user();

        // Validasi: hanya mitra pemilik destinasi atau admin yang boleh membalas
        if (! $user->isAdmin() && $review->destination->user_id !== $user->id) {
            return response()->json([
                'message' => 'Anda tidak memiliki hak akses untuk membalas ulasan di destinasi ini.',
            ], 403);
        }

        $validated = $request->validate([
            'reply' => ['required', 'string', 'max:2000'],
        ]);

        $review->update([
            'reply' => $validated['reply'],
            'replied_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tanggapan ulasan berhasil disimpan.',
            'data' => $review->load('user:id,name,avatar'),
        ]);
    }

    public function destroy(Request $request, Review $review)
    {
        // owner or admin may delete (admin = moderation)
        if (! $request->user()->isAdmin() && $review->user_id !== $request->user()->id) {
            abort(403, 'Forbidden.');
        }

        $destination = $review->destination;
        $review->delete();
        $destination->recalcRating();

        return response()->json(['message' => 'Review deleted.']);
    }

    private function authorizeOwner(Request $request, Review $review): void
    {
        if ($review->user_id !== $request->user()->id) {
            abort(403, 'Forbidden.');
        }
    }
}