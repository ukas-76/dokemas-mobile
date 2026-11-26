import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';
import 'mitra_edit_destinasi_page.dart';

class MitraDestinasiPage extends StatelessWidget {
  const MitraDestinasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MitraProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final dest = prov.destination;

        if (dest == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Belum Ada Destinasi', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  const Text(
                    'Destinasi Anda akan muncul di sini setelah proses verifikasi selesai.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => prov.fetchStatus(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => prov.fetchStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Foto Cover
                _CoverSection(dest: dest),
                const SizedBox(height: 16),

                // Info Utama
                _InfoSection(dest: dest),
                const SizedBox(height: 16),

                // Status Publikasi
                _StatusSection(dest: dest),
                const SizedBox(height: 16),

                // Fasilitas
                _FasilitasSection(dest: dest),
                const SizedBox(height: 16),

                // Galeri Foto
                _GaleriSection(dest: dest),
                const SizedBox(height: 20),

                // Tombol Edit
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MitraEditDestinasiPage(destination: dest),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Data Destinasi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
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

// ─── Cover Section ─────────────────────────────────────────────────────────────
class _CoverSection extends StatelessWidget {
  final MitraDestinationSummary dest;
  const _CoverSection({required this.dest});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: (dest.thumbnailUrl != null && dest.thumbnailUrl!.isNotEmpty)
            ? Image.network(dest.thumbnailUrl!, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE2E8F0),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 56, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text('Belum ada foto cover', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

// ─── Info Section ──────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final MitraDestinationSummary dest;
  const _InfoSection({required this.dest});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Informasi Destinasi',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _InfoRow(icon: Icons.label_outline, label: 'Nama', value: dest.name),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Alamat', value: dest.address ?? '-'),
          _InfoRow(icon: Icons.map_outlined, label: 'Kecamatan', value: dest.district ?? '-'),
          _InfoRow(
            icon: Icons.attach_money_rounded,
            label: 'Harga Tiket',
            value: dest.price != null
                ? (dest.price == 0 ? 'Gratis' : 'Rp ${dest.price!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}')
                : '-',
          ),
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Jam Buka',
            value: dest.is24Hours ? 'Buka 24 Jam' : (dest.openingHours ?? '-'),
          ),
          _InfoRow(icon: Icons.phone_outlined, label: 'CS/WA', value: dest.csPhone ?? '-'),
          if (dest.description != null)
            _InfoRow(icon: Icons.description_outlined, label: 'Deskripsi', value: dest.description!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

// ─── Status Section ───────────────────────────────────────────────────────────
class _StatusSection extends StatelessWidget {
  final MitraDestinationSummary dest;
  const _StatusSection({required this.dest});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> cfg;
    switch (dest.status) {
      case 'published':
        cfg = {'color': AppColors.success, 'icon': Icons.check_circle_outline, 'label': 'Tayang / Publik',
          'desc': 'Destinasi Anda sudah tampil di aplikasi wisatawan.'};
        break;
      case 'draft':
        cfg = {'color': AppColors.danger, 'icon': Icons.cancel_outlined, 'label': 'Draft / Ditolak',
          'desc': 'Konten ditolak oleh kurator. Hubungi admin untuk informasi lebih lanjut.'};
        break;
      default:
        cfg = {'color': AppColors.warning, 'icon': Icons.hourglass_top_rounded, 'label': 'Menunggu Kurasi',
          'desc': 'Konten destinasi sedang ditinjau oleh kurator Dinporabudpar Banyumas.'};
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (cfg['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(cfg['icon'] as IconData, color: cfg['color'] as Color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${cfg['label']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: cfg['color'] as Color)),
                const SizedBox(height: 4),
                Text(cfg['desc'] as String, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fasilitas Section ────────────────────────────────────────────────────────
class _FasilitasSection extends StatelessWidget {
  final MitraDestinationSummary dest;
  const _FasilitasSection({required this.dest});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Fasilitas Tersedia',
      icon: Icons.business_center_outlined,
      child: dest.facilities.isEmpty
          ? const Text('Belum ada fasilitas terdaftar.', style: AppTextStyles.body)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dest.facilities.map((f) {
                final name = f['name']?.toString() ?? '';
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
    );
  }
}

// ─── Galeri Section ───────────────────────────────────────────────────────────
class _GaleriSection extends StatelessWidget {
  final MitraDestinationSummary dest;
  const _GaleriSection({required this.dest});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Galeri Foto',
      icon: Icons.photo_library_outlined,
      child: dest.images.isEmpty
          ? const Text('Belum ada foto galeri.', style: AppTextStyles.body)
          : SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dest.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final img = dest.images[i];
                  final url = (img['image_url'] ?? img['url'] ?? '').toString();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, width: 90, height: 90, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90, height: 90, color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                        )),
                  );
                },
              ),
            ),
    );
  }
}

// ─── Shared Card wrapper ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.title.copyWith(fontSize: 14)),
          ]),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
