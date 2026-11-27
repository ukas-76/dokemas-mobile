class ChatConversation {
  final int id;
  final ChatUser user;
  final ChatUser mitra;
  final String? destinationName;
  final int? destinationId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.user,
    required this.mitra,
    this.destinationName,
    this.destinationId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      user: ChatUser.fromJson(json['user'] ?? {}),
      mitra: ChatUser.fromJson(json['mitra'] ?? {}),
      destinationName: json['destination']?['name'],
      destinationId: json['destination']?['id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatUser {
  final int id;
  final String name;
  final String? avatar;

  ChatUser({required this.id, required this.name, this.avatar});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'],
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderRole;
  final String senderName;
  final String message;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderRole: json['sender_role'],
      senderName: json['sender_name'] ?? '',
      message: json['message'],
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
