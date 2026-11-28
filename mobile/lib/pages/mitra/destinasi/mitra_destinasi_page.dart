import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';
import '../../detail_destinasi_screen.dart';
import 'mitra_edit_destinasi_page.dart';

class MitraDestinasiPage extends StatefulWidget {
  const MitraDestinasiPage({super.key});

  @override
  State<MitraDestinasiPage> createState() => _MitraDestinasiPageState();
}

class _MitraDestinasiPageState extends State<MitraDestinasiPage> {
  bool _isDescExpanded = false;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('$label berhasil disalin ke clipboard!')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String urlString, String fallbackError) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        _copyToClipboard(context, urlString, 'Tautan');
      }
    } catch (_) {
      if (!context.mounted) return;
      _copyToClipboard(context, urlString, 'Tautan');
    }
  }

  Future<void> _contactCs(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final waNumber = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone.replaceAll('+', '');
    final waUrl = 'https://wa.me/$waNumber';
    await _openUrl(context, waUrl, 'Gagal membuka WhatsApp');
  }

  void _openPreview(BuildContext context, MitraDestinationSummary dest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailDestinasiScreen(
          destinationId: dest.id,
          title: dest.name,
          imageUrl: dest.effectiveThumbnailUrl ?? dest.thumbnailUrl ?? '',
          rating: dest.ratingAvg > 0 ? dest.ratingAvg.toStringAsFixed(1) : '4.5',
          reviewCount: '${dest.ratingCount}',
          location: dest.address ?? (dest.district != null ? '${dest.district}, Banyumas' : 'Banyumas'),
          price: dest.price != null && dest.price! > 0 ? 'Rp ${dest.price!.toInt()}' : 'Gratis',
          distance: '0 km',
          openingHours: dest.is24Hours ? 'Buka 24 Jam' : (dest.openingHours ?? '08:00 - 17:00'),
          description: dest.description ?? 'Destinasi mitra resmi DOKEMAS Banyumas.',
          galleryImages: dest.images.map((img) {
            final url = (img['image_url'] ?? img['url'] ?? img['image_path'] ?? '').toString();
            if (url.startsWith('http')) return url.replaceFirst('http://', 'https://');
            return '${ApiConfig.storageBaseUrl}/$url';
          }).toList(),
        ),
      ),
    );
  }

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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_outlined, size: 56, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('Belum Ada Destinasi Terdaftar', style: AppTextStyles.heading2, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'Destinasi Anda akan tampil di sini segera setelah pengajuan kemitraan diverifikasi oleh dinas.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => prov.fetchStatus(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Muat Ulang'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Cover Banner Interaktif
                _buildHeroBanner(context, dest),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Hub Aksi Cepat (Quick Action Bar)
                      _buildQuickActionBar(context, dest),
                      const SizedBox(height: 18),

                      // 3. Grid Kartu KPI / Metrik Operasional
                      _buildMetricsGrid(context, dest),
                      const SizedBox(height: 20),

                      // 4. Kartu Tentang & Deskripsi
                      _buildAboutSection(dest),
                      const SizedBox(height: 18),

                      // 5. Kartu Fasilitas Tersedia
                      _buildFacilitiesSection(context, dest),
                      const SizedBox(height: 18),

                      // 6. Galeri Foto Interaktif
                      _buildGallerySection(context, dest),
                      const SizedBox(height: 18),

                      // 7. Lokasi & Navigasi
                      _buildLocationSection(context, dest),
                      const SizedBox(height: 28),

                      // 8. Tombol Utama Edit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MitraEditDestinasiPage(destination: dest),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 22),
                          label: const Text(
                            'Perbarui Data Wisata',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 1. Hero Banner ─────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context, MitraDestinationSummary dest) {
    final thumb = dest.effectiveThumbnailUrl;
    final hasThumb = thumb != null && thumb.isNotEmpty;

    return Stack(
      children: [
        // Background Image or Gradient Card
        Container(
          width: double.infinity,
          height: 230,
          decoration: BoxDecoration(
            color: const Color(0xFF071B34),
            image: hasThumb
                ? DecorationImage(
                    image: NetworkImage(thumb),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasThumb
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF071B34), Color(0xFF0C2D54), Color(0xFF1E6F1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Foto Cover Belum Diatur',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketuk "Edit" di bawah untuk mengunggah cover',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),

        // Gradient Overlay (Darkens bottom for text readability)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // Badges Top Bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge Pill
              _buildStatusPill(dest.status),
              // Category Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.landscape_rounded, color: Color(0xFF4ADE80), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      dest.district ?? 'Banyumas',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Destination Title & Location Bottom Info
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dest.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_rounded, color: Color(0xFF4ADE80), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dest.address ?? 'Kabupaten Banyumas, Jawa Tengah',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color border;
    Color dot;
    String label;

    switch (status) {
      case 'published':
        bg = const Color(0xFF16A34A).withValues(alpha: 0.9);
        border = const Color(0xFF4ADE80);
        dot = const Color(0xFF86EFAC);
        label = 'PUBLIK / TAYANG';
        break;
      case 'draft':
        bg = const Color(0xFFDC2626).withValues(alpha: 0.9);
        border = const Color(0xFFF87171);
        dot = const Color(0xFFFCA5A5);
        label = 'DRAFT / DITOLAK';
        break;
      default:
        bg = const Color(0xFFD97706).withValues(alpha: 0.9);
        border = const Color(0xFFFCD34D);
        dot = const Color(0xFFFEF3C7);
        label = 'MENUNGGU KURASI';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }

  // ─── 2. Quick Action Bar ────────────────────────────────────────────────────
  Widget _buildQuickActionBar(BuildContext context, MitraDestinationSummary dest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionItem(
            icon: Icons.preview_rounded,
            color: const Color(0xFF2563EB),
            label: 'Pratinjau',
            onTap: () => _openPreview(context, dest),
          ),
          _buildActionItem(
            icon: Icons.edit_note_rounded,
            color: AppColors.primary,
            label: 'Edit Info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MitraEditDestinasiPage(destination: dest),
                ),
              );
            },
          ),
          _buildActionItem(
            icon: Icons.chat_rounded,
            color: const Color(0xFF16A34A),
            label: 'Test WA',
            onTap: () {
              if (dest.csPhone != null && dest.csPhone!.isNotEmpty) {
                _contactCs(context, dest.csPhone!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor CS/WA belum diisi')),
                );
              }
            },
          ),
          _buildActionItem(
            icon: Icons.map_rounded,
            color: const Color(0xFFD97706),
            label: 'Buka Maps',
            onTap: () {
              final query = dest.mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${dest.name} Banyumas")}';
              _openUrl(context, query, 'Gagal membuka Google Maps');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. Metrics Grid (KPI Cards) ────────────────────────────────────────────
  Widget _buildMetricsGrid(BuildContext context, MitraDestinationSummary dest) {
    final priceText = dest.price != null
        ? (dest.price == 0 ? 'Gratis' : 'Rp ${dest.price!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}')
        : '-';

    final hoursText = dest.is24Hours ? '24 Jam Nonstop' : (dest.openingHours ?? '08:00 - 17:00');

    return Row(
      children: [
        // Kartu Tiket
        Expanded(
          child: _buildMetricCard(
            icon: Icons.confirmation_number_outlined,
            iconColor: const Color(0xFF16A34A),
            title: 'Tarif Tiket',
            value: priceText,
            subtitle: '/ pengunjung',
          ),
        ),
        const SizedBox(width: 12),
        // Kartu Jam Buka
        Expanded(
          child: _buildMetricCard(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Jam Buka',
            value: hoursText,
            subtitle: 'WIB',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── 4. About Section ───────────────────────────────────────────────────────
  Widget _buildAboutSection(MitraDestinationSummary dest) {
    final desc = dest.description ?? 'Belum ada deskripsi yang ditambahkan untuk tempat wisata ini.';
    final isLong = desc.length > 160;

    return _buildSectionCard(
      title: 'Deskripsi Destinasi',
      icon: Icons.notes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isDescExpanded || !isLong ? desc : '${desc.substring(0, 160)}...',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Color(0xFF334155),
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDescExpanded ? 'Tutup Kembali' : 'Baca Selengkapnya',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      _isDescExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 5. Facilities Section ──────────────────────────────────────────────────
  Widget _buildFacilitiesSection(BuildContext context, MitraDestinationSummary dest) {
    return _buildSectionCard(
      title: 'Fasilitas Tersedia',
      icon: Icons.local_activity_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${dest.facilities.length} Fasilitas',
            style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MitraEditDestinasiPage(destination: dest, initialSection: 'fasilitas'),
                ),
              );
            },
            child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          ),
        ],
      ),
      child: dest.facilities.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    const Icon(Icons.beach_access_rounded, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 6),
                    const Text('Belum ada fasilitas yang dipilih.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MitraEditDestinasiPage(destination: dest, initialSection: 'fasilitas'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Fasilitas'),
                    ),
                  ],
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dest.facilities.map((f) {
                final name = f['name']?.toString() ?? 'Fasilitas';
                final icon = _getFacilityIcon(name);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  IconData _getFacilityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('toilet') || lower.contains('wc')) return Icons.wc_rounded;
    if (lower.contains('parkir')) return Icons.local_parking_rounded;
    if (lower.contains('musholla') || lower.contains('masjid')) return Icons.mosque_rounded;
    if (lower.contains('makan') || lower.contains('warung') || lower.contains('kuliner')) return Icons.restaurant_rounded;
    if (lower.contains('foto') || lower.contains('spot')) return Icons.camera_alt_rounded;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('anak') || lower.contains('bermain')) return Icons.toys_rounded;
    if (lower.contains('penginapan') || lower.contains('hotel')) return Icons.hotel_rounded;
    return Icons.check_circle_outline_rounded;
  }

  // ─── 6. Gallery Section ─────────────────────────────────────────────────────
  Widget _buildGallerySection(BuildContext context, MitraDestinationSummary dest) {
    return _buildSectionCard(
      title: 'Galeri Foto Wisata',
      icon: Icons.photo_library_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${dest.images.length} Foto',
            style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MitraEditDestinasiPage(destination: dest, initialSection: 'galeri'),
                ),
              );
            },
            child: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.primary),
          ),
        ],
      ),
      child: dest.images.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.collections_outlined, size: 38, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  const Text('Belum ada foto galeri pendukung', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MitraEditDestinasiPage(destination: dest, initialSection: 'galeri'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Unggah Foto Galeri'),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dest.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final img = dest.images[i];
                  final url = (img['image_url'] ?? img['url'] ?? img['image_path'] ?? '').toString();

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 130,
                      decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ─── 7. Location Section ────────────────────────────────────────────────────
  Widget _buildLocationSection(BuildContext context, MitraDestinationSummary dest) {
    return _buildSectionCard(
      title: 'Lokasi & Titik Kunjungan',
      icon: Icons.near_me_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.address ?? 'Alamat belum diatur',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kecamatan: ${dest.district ?? "Baturraden"}, Kabupaten Banyumas',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (dest.address != null) {
                      _copyToClipboard(context, dest.address!, 'Alamat');
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin Alamat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final query = dest.mapsUrl ?? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${dest.name} Banyumas")}';
                    _openUrl(context, query, 'Gagal membuka Google Maps');
                  },
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Petunjuk Arah'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF071B34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper Card Wrapper ────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }
}
