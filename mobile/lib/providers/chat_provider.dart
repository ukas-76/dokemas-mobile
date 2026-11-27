import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../config/api_config.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _sendingMessage = false;
  String? _error;
  Timer? _pollingTimer;
  int? _activeConversationId;

  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get sendingMessage => _sendingMessage;
  String? get error => _error;

  // ─── Conversations ────────────────────────────────────────────────────────

  Future<void> fetchConversations(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        _conversations = data.map((e) => ChatConversation.fromJson(e)).toList();
      } else {
        _error = 'Gagal memuat percakapan';
      }
    } catch (e) {
      _error = 'Koneksi gagal';
    }
    _loading = false;
    notifyListeners();
  }

  /// Buka / buat percakapan baru dengan mitra berdasarkan destination_id
  Future<ChatConversation?> openConversation(String token, int destinationId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'destination_id': destinationId}),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body)['data'];
        return ChatConversation.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<void> fetchMessages(String token, int conversationId) async {
    _loading = true;
    _error = null;
    _activeConversationId = conversationId;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        _messages = data.map((e) => ChatMessage.fromJson(e)).toList();
      } else {
        _error = 'Gagal memuat pesan';
      }
    } catch (e) {
      _error = 'Koneksi gagal';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String token, int conversationId, String text) async {
    _sendingMessage = true;
    notifyListeners();
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'message': text}),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body)['data'];
        _messages.add(ChatMessage.fromJson(data));
        _sendingMessage = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _sendingMessage = false;
    notifyListeners();
    return false;
  }

  // ─── Polling ──────────────────────────────────────────────────────────────

  /// Mulai polling pesan baru setiap 3 detik (di dalam chat room)
  void startPolling(String token, int conversationId) {
    stopPolling();
    _activeConversationId = conversationId;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _pollMessages(token, conversationId);
    });
  }

  Future<void> _pollMessages(String token, int conversationId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        final newMessages = data.map((e) => ChatMessage.fromJson(e)).toList();
        if (newMessages.length != _messages.length) {
          _messages = newMessages;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ─── Unread Badge ─────────────────────────────────────────────────────────

  Future<void> fetchUnreadCount(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations/unread-count'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        _unreadCount = jsonDecode(res.body)['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearMessages() {
    _messages = [];
    _activeConversationId = null;
    _error = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
