import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';

class MitraDashboardPage extends StatelessWidget {
  final VoidCallback onNavigateToDestinasi;
  const MitraDashboardPage({super.key, required this.onNavigateToDestinasi});

  @override
  Widget build(BuildContext context) {
    return Consumer<MitraProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (prov.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(prov.error!, textAlign: TextAlign.center, style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => prov.fetchStatus(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }

        final status = prov.status;
        final dest = prov.destination;
        final verStatus = status?.verificationStatus ?? 'pending';

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => prov.fetchStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu Status Verifikasi
                _VerificationStatusCard(
                  status: verStatus,
                  rejectionReason: status?.rejectionReason,
                ),
                const SizedBox(height: 16),

                // Kartu Destinasi
                if (dest != null) ...[
                  _DestinationCard(destination: dest, onTap: onNavigateToDestinasi),
                  const SizedBox(height: 16),
                  // Statistik
                  _StatsRow(destination: dest),
                  const SizedBox(height: 16),
                ] else ...[
                  _NoDestinationCard(onTap: onNavigateToDestinasi),
                  const SizedBox(height: 16),
                ],

                // Panduan Langkah (hanya tampil jika pending)
                if (verStatus == 'pending') ...[
                  _StepsGuideCard(),
                  const SizedBox(height: 16),
                ],

                // Info Kontak Dinas
                _InfoCard(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Butuh Bantuan?',
                  subtitle: 'Hubungi Dinporabudpar Banyumas\n(0281) 123-4567',
                  color: AppColors.info,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Widget: Status Verifikasi ────────────────────────────────────────────────
class _VerificationStatusCard extends StatelessWidget {
  final String status;
  final String? rejectionReason;
  const _VerificationStatusCard({required this.status, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cfg['color'].withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg['color'].withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cfg['icon'] as IconData, color: cfg['color'] as Color, size: 22),
              const SizedBox(width: 10),
              Text(
                'Status Kemitraan',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg['color'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cfg['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(cfg['desc'] as String, style: AppTextStyles.body),
          if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📋 Catatan Admin: $rejectionReason',
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'verified':
        return {
          'icon': Icons.verified_rounded,
          'color': AppColors.success,
          'label': 'Terverifikasi',
          'desc': 'Akun mitra Anda telah diverifikasi oleh Dinporabudpar Banyumas.',
        };
      case 'rejected':
        return {
          'icon': Icons.cancel_rounded,
          'color': AppColors.danger,
          'label': 'Ditolak',
          'desc': 'Pengajuan Anda ditolak. Periksa catatan admin dan hubungi dinas.',
        };
      default:
        return {
          'icon': Icons.hourglass_top_rounded,
          'color': AppColors.warning,
          'label': 'Menunggu',
          'desc': 'Pengajuan Anda sedang ditinjau oleh tim Dinporabudpar Banyumas.',
        };
    }
  }
}

// ─── Widget: Kartu Destinasi ──────────────────────────────────────────────────
class _DestinationCard extends StatelessWidget {
  final MitraDestinationSummary destination;
  final VoidCallback onTap;
  const _DestinationCard({required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dest = destination;
    final pubColor = dest.status == 'published' ? AppColors.success : (dest.status == 'draft' ? AppColors.danger : AppColors.warning);
    final pubLabel = dest.status == 'published' ? 'Tayang' : (dest.status == 'draft' ? 'Draft' : 'Menunggu Kurasi');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: (dest.thumbnailUrl != null && dest.thumbnailUrl!.isNotEmpty)
                    ? Image.network(dest.thumbnailUrl!, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholderImage())
                    : _placeholderImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(dest.name,
                            style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pubColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pubColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(pubLabel,
                            style: TextStyle(color: pubColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (dest.address != null)
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(dest.address!,
                            style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Kelola Destinasi →',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        color: const Color(0xFFE2E8F0),
        child: const Center(child: Icon(Icons.image_outlined, size: 48, color: AppColors.textMuted)),
      );
}

// ─── Widget: Statistik ────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final MitraDestinationSummary destination;
  const _StatsRow({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.star_rounded,
          value: destination.ratingAvg == 0 ? '-' : destination.ratingAvg.toStringAsFixed(1),
          label: 'Rating',
          color: AppColors.warning,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.rate_review_outlined,
          value: '${destination.ratingCount}',
          label: 'Ulasan',
          color: AppColors.info,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.business_center_outlined,
          value: '${destination.facilities.length}',
          label: 'Fasilitas',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: No Destination ───────────────────────────────────────────────────
class _NoDestinationCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoDestinationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Belum Ada Destinasi', style: AppTextStyles.title),
          const SizedBox(height: 6),
          const Text('Data destinasi Anda akan muncul setelah proses verifikasi selesai.',
              textAlign: TextAlign.center, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ─── Widget: Panduan Langkah ──────────────────────────────────────────────────
class _StepsGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
            SizedBox(width: 8),
            Text('Proses Verifikasi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
          ]),
          const SizedBox(height: 12),
          _Step(no: '1', text: 'Tim Dinporabudpar memeriksa legalitas (NIB, NIK).'),
          _Step(no: '2', text: 'Konten destinasi dikurasi oleh admin.'),
          _Step(no: '3', text: 'Destinasi diterbitkan dan tampil di aplikasi wisatawan.'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String no;
  final String text;
  const _Step({required this.no, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle),
            child: Center(child: Text(no, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

// ─── Widget: Info Card ────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _InfoCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
