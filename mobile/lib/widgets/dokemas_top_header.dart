import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/notification_page.dart';
import 'dokemas_logo.dart';

class DokemasTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onAvatarTap;

  const DokemasTopHeader({super.key, this.onAvatarTap});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final avatarUrl = user?.avatarUrl;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          const DokemasLogo(width: 32, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DOKEMAS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.near_me_outlined,
                      size: 12,
                      color: Color(0xFF1E6F1D),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Purwokerto, Banyumas',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
              Positioned(
                top: 1,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

