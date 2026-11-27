import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../models/chat_models.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ChatProvider>().fetchConversations(token);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final isMitra = auth.user?.role == 'mitra';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: chat.loading
          ? const Center(child: CircularProgressIndicator())
          : chat.conversations.isEmpty
              ? _buildEmpty(isMitra)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.conversations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) =>
                        _ConversationTile(
                          conv: chat.conversations[i],
                          currentUserId: auth.user?.id ?? 0,
                          isMitra: isMitra,
                          timeText: _formatTime(chat.conversations[i].lastMessageAt),
                        ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool isMitra) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            isMitra
                ? 'Belum ada pesan dari wisatawan'
                : 'Belum ada percakapan.\nMulai chat dengan mitra dari halaman destinasi!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conv;
  final int currentUserId;
  final bool isMitra;
  final String timeText;

  const _ConversationTile({
    required this.conv,
    required this.currentUserId,
    required this.isMitra,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    // Tampilkan nama lawan bicara
    final other = isMitra ? conv.user : conv.mitra;
    final hasUnread = conv.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          other.name.isNotEmpty ? other.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              other.name,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(timeText,
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? AppColors.primary : AppColors.textSecondary,
              )),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conv.destinationName != null)
            Text(
              conv.destinationName!,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  conv.lastMessage ?? 'Belum ada pesan',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${conv.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(conversation: conv),
          ),
        );
      },
    );
  }
}
