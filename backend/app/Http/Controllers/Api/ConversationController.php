<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Destination;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    /**
     * GET /api/conversations
     * Daftar semua percakapan milik user/mitra yang login.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $isMitra = $user->role === 'mitra';

        $conversations = Conversation::with([
            'user:id,name,avatar',
            'mitra:id,name,avatar',
            'destination:id,name',
        ])
        ->when($isMitra, fn($q) => $q->where('mitra_id', $user->id))
        ->when(!$isMitra, fn($q) => $q->where('user_id', $user->id))
        ->orderByDesc('last_message_at')
        ->get()
        ->map(function ($conv) use ($user) {
            $lastMsg = $conv->messages()->latest()->first();
            $unread = $conv->unreadCountFor($user->id);
            return [
                'id'            => $conv->id,
                'user'          => $conv->user,
                'mitra'         => $conv->mitra,
                'destination'   => $conv->destination,
                'last_message'  => $lastMsg?->message,
                'last_message_at' => $conv->last_message_at,
                'unread_count'  => $unread,
            ];
        });

        return response()->json(['data' => $conversations]);
    }

    /**
     * POST /api/conversations
     * Buat atau buka percakapan antara user & mitra berdasarkan destination_id.
     * Body: { destination_id }
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'destination_id' => 'required|exists:destinations,id',
        ]);

        $user = $request->user();
        $destination = Destination::findOrFail($request->destination_id);

        // Pastikan mitra_id ada (hanya destinasi milik mitra yang bisa dihubungi)
        if (!$destination->user_id) {
            return response()->json(['message' => 'Destinasi ini tidak memiliki mitra.'], 422);
        }

        $mitraId = $destination->user_id;

        // Jangan boleh user membuka chat dengan diri sendiri
        if ($user->id === $mitraId) {
            return response()->json(['message' => 'Tidak dapat membuka percakapan dengan diri sendiri.'], 422);
        }

        $conversation = Conversation::firstOrCreate(
            [
                'user_id'        => $user->id,
                'mitra_id'       => $mitraId,
                'destination_id' => $destination->id,
            ],
            ['last_message_at' => now()]
        );

        $conversation->load(['user:id,name,avatar', 'mitra:id,name,avatar', 'destination:id,name']);

        return response()->json(['data' => $conversation], 201);
    }

    /**
     * GET /api/conversations/{id}/messages
     * Ambil semua pesan dalam satu percakapan.
     * Otomatis tandai pesan lawan sebagai sudah dibaca.
     */
    public function messages(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $conv = $this->findConversationForUser($id, $user->id);

        // Tandai pesan dari lawan sebagai dibaca
        Message::where('conversation_id', $conv->id)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $messages = $conv->messages()->with('sender:id,name,avatar')->get()
            ->map(fn($m) => [
                'id'          => $m->id,
                'sender_id'   => $m->sender_id,
                'sender_role' => $m->sender_role,
                'sender_name' => $m->sender->name ?? 'Unknown',
                'message'     => $m->message,
                'read_at'     => $m->read_at,
                'created_at'  => $m->created_at,
            ]);

        return response()->json(['data' => $messages]);
    }

    /**
     * POST /api/conversations/{id}/messages
     * Kirim pesan baru.
     * Body: { message }
     */
    public function sendMessage(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'message' => 'required|string|max:2000',
        ]);

        $user = $request->user();
        $conv = $this->findConversationForUser($id, $user->id);

        $role = $user->role === 'mitra' ? 'mitra' : 'user';

        $message = Message::create([
            'conversation_id' => $conv->id,
            'sender_id'       => $user->id,
            'sender_role'     => $role,
            'message'         => $request->message,
        ]);

        $conv->update(['last_message_at' => now()]);

        return response()->json([
            'data' => [
                'id'          => $message->id,
                'sender_id'   => $message->sender_id,
                'sender_role' => $message->sender_role,
                'sender_name' => $user->name,
                'message'     => $message->message,
                'read_at'     => null,
                'created_at'  => $message->created_at,
            ],
        ], 201);
    }

    /**
     * GET /api/conversations/unread-count
     * Jumlah total pesan belum dibaca (untuk badge notifikasi).
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();
        $isMitra = $user->role === 'mitra';

        $count = Message::whereHas('conversation', function ($q) use ($user, $isMitra) {
            $q->when($isMitra, fn($q) => $q->where('mitra_id', $user->id))
              ->when(!$isMitra, fn($q) => $q->where('user_id', $user->id));
        })
        ->where('sender_id', '!=', $user->id)
        ->whereNull('read_at')
        ->count();

        return response()->json(['unread_count' => $count]);
    }

    // Helper: pastikan user berhak mengakses percakapan ini
    private function findConversationForUser(int $convId, int $userId): Conversation
    {
        return Conversation::where('id', $convId)
            ->where(fn($q) => $q->where('user_id', $userId)->orWhere('mitra_id', $userId))
            ->firstOrFail();
    }
}
