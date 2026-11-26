import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/mitra_provider.dart';
import '../../main_screen.dart';
import '../../user/profile/change_password_page.dart';
import '../../user/profile/edit_profile_page.dart';

class MitraProfilPage extends StatelessWidget {
  const MitraProfilPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun DOKEMAS Mitra?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final nav = Navigator.of(context, rootNavigator: true);
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              await authProv.logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final mitraProv = context.watch<MitraProvider>();
    final user = authProv.user;
    final status = mitraProv.status;
    final verStatus = status?.verificationStatus ?? 'pending';

    final avatarUrl = user?.avatarUrl;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Profil ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF061B34), Color(0xFF0A2748), Color(0xFF051529)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.65), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl) : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.business_center_rounded, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? 'Mitra', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                const SizedBox(height: 10),
                // Badge verifikasi
                _VerifBadge(status: verStatus),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Legalitas ───────────────────────────────────────────
                _Section(
                  title: 'DATA LEGALITAS',
                  tiles: [
                    _InfoTile(icon: Icons.badge_outlined, label: 'Jenis Entitas', value: status?.entityType ?? '-'),
                    _InfoTile(icon: Icons.work_outline_rounded, label: 'Jabatan', value: status?.position ?? '-'),
                    _InfoTile(icon: Icons.credit_card_outlined, label: 'NIK', value: status?.nik ?? '-'),
                    _InfoTile(icon: Icons.business_outlined, label: 'NIB', value: status?.nib ?? '-'),
                  ],
                ),

                // ── Rekening ────────────────────────────────────────────
                _Section(
                  title: 'REKENING PENCAIRAN',
                  tiles: [
                    _InfoTile(icon: Icons.account_balance_outlined, label: 'Bank', value: status?.bankName ?? '-'),
                    _InfoTile(
                      icon: Icons.payment_outlined,
                      label: 'No. Rekening',
                      value: _maskAccountNumber(status?.bankAccountNumber),
                    ),
                    _InfoTile(icon: Icons.person_outline_rounded, label: 'Pemilik', value: status?.bankAccountHolder ?? '-'),
                  ],
                ),

                // ── Akun ────────────────────────────────────────────────
                _Section(
                  title: 'AKUN SAYA',
                  tiles: [
                    _ActionTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profil',
                      onTap: () {
                        if (user != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user)));
                        }
                      },
                    ),
                    _ActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ganti Password',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tombol Keluar
                InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text('Keluar', style: TextStyle(color: AppColors.danger, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskAccountNumber(String? num) {
    if (num == null || num.isEmpty) return '-';
    if (num.length <= 4) return num;
    return '${'*' * (num.length - 4)}${num.substring(num.length - 4)}';
  }
}

class _VerifBadge extends StatelessWidget {
  final String status;
  const _VerifBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;
    switch (status) {
      case 'verified':
        color = AppColors.success; label = 'Mitra Terverifikasi'; icon = Icons.verified_rounded;
        break;
      case 'rejected':
        color = AppColors.danger; label = 'Pengajuan Ditolak'; icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.warning; label = 'Menunggu Verifikasi'; icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
          child: Text(title,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) => tiles[i],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
