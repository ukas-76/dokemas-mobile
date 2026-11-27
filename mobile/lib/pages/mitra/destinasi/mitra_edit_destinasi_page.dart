import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';

class LocalImageItem {
  final XFile file;
  final Uint8List bytes;
  LocalImageItem({required this.file, required this.bytes});
}

class MitraEditDestinasiPage extends StatefulWidget {
  final MitraDestinationSummary destination;
  final String? initialSection; // 'fasilitas' | 'galeri' | null

  const MitraEditDestinasiPage({
    super.key,
    required this.destination,
    this.initialSection,
  });

  @override
  State<MitraEditDestinasiPage> createState() => _MitraEditDestinasiPageState();
}

class _MitraEditDestinasiPageState extends State<MitraEditDestinasiPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _fasilitasKey = GlobalKey();
  final _galeriKey = GlobalKey();

  bool _saving = false;
  bool _is24Hours = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _openingHoursCtrl;
  late final TextEditingController _csPhoneCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _mapsUrlCtrl;

  // Facilities
  List<Map<String, dynamic>> _allFacilities = [];
  bool _loadingFacilities = true;
  final Set<int> _selectedFacilityIds = {};

  // Gallery Images
  late List<Map<String, dynamic>> _existingImages;
  final List<LocalImageItem> _newImages = [];
  bool _isDeletingImage = false;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _nameCtrl = TextEditingController(text: d.name);
    _addressCtrl = TextEditingController(text: d.address ?? '');
    _districtCtrl = TextEditingController(text: d.district ?? '');
    _priceCtrl = TextEditingController(text: d.price?.toInt().toString() ?? '0');
    _openingHoursCtrl = TextEditingController(text: d.openingHours ?? '');
    _csPhoneCtrl = TextEditingController(text: d.csPhone ?? '');
    _descCtrl = TextEditingController(text: d.description ?? '');
    _mapsUrlCtrl = TextEditingController(text: d.mapsUrl ?? '');
    _is24Hours = d.is24Hours;

    // Existing facilities
    for (final f in d.facilities) {
      final id = f['id'];
      if (id is int) {
        _selectedFacilityIds.add(id);
      } else if (id != null) {
        final parsed = int.tryParse(id.toString());
        if (parsed != null) _selectedFacilityIds.add(parsed);
      }
    }

    // Existing images
    _existingImages = List<Map<String, dynamic>>.from(d.images);

    // Fetch master facilities
    _fetchFacilities();

    // Auto-scroll jika ada initialSection
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.initialSection!);
      });
    }
  }

  void _scrollToSection(String section) {
    BuildContext? targetContext;
    if (section == 'fasilitas') {
      targetContext = _fasilitasKey.currentContext;
    } else if (section == 'galeri') {
      targetContext = _galeriKey.currentContext;
    }
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _fetchFacilities() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.facilities),
        headers: ApiConfig.defaultHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List) ? data : (data['data'] as List? ?? []);
        if (mounted) {
          setState(() {
            _allFacilities = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _loadingFacilities = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingFacilities = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _priceCtrl.dispose();
    _openingHoursCtrl.dispose();
    _csPhoneCtrl.dispose();
    _descCtrl.dispose();
    _mapsUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNewImages() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;

      for (final file in picked) {
        final bytes = await file.readAsBytes();
        setState(() {
          _newImages.add(LocalImageItem(file: file, bytes: bytes));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _deleteExistingImage(Map<String, dynamic> img) async {
    final imgId = img['id'];
    if (imgId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto Galeri?'),
        content: const Text('Foto ini akan dihapus permanen dari galeri destinasi Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeletingImage = true);
    final prov = context.read<MitraProvider>();
    final parsedId = (imgId is int) ? imgId : int.parse(imgId.toString());
    final error = await prov.deleteGalleryImage(
      destinationId: widget.destination.id,
      imageId: parsedId,
    );

    if (!mounted) return;
    setState(() => _isDeletingImage = false);

    if (error == null) {
      setState(() {
        _existingImages.removeWhere((item) => item['id'] == imgId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Foto berhasil dihapus'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setCover(Map<String, dynamic> img) async {
    final imgId = img['id'];
    if (imgId == null) return;
    final parsedId = (imgId is int) ? imgId : int.parse(imgId.toString());

    setState(() => _saving = true);
    final prov = context.read<MitraProvider>();
    final error = await prov.setCoverImage(
      destinationId: widget.destination.id,
      imageId: parsedId,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌟 Foto cover utama berhasil diperbarui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'opening_hours': _openingHoursCtrl.text.trim(),
      'cs_phone': _csPhoneCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'maps_url': _mapsUrlCtrl.text.trim(),
      'is_24_hours': _is24Hours ? '1' : '0',
      'facility_ids': _selectedFacilityIds.toList(),
    };

    final prov = context.read<MitraProvider>();
    final error = await prov.updateDestination(
      destinationId: widget.destination.id,
      fields: fields,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Jika ada foto baru yang dipilih, unggah sekarang
    if (_newImages.isNotEmpty) {
      final uploadError = await prov.uploadGalleryImages(
        destinationId: widget.destination.id,
        images: _newImages.map((e) => e.file).toList(),
      );

      if (!mounted) return;

      if (uploadError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peringatan: Data tersimpan, namun foto gagal: $uploadError'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Data destinasi, fasilitas & galeri berhasil diperbarui!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Destinasi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Informasi Utama
              _buildSection('Informasi Utama', [
                _field(_nameCtrl, 'Nama Destinasi', Icons.label_outline, required: true),
                _field(_addressCtrl, 'Alamat Lengkap', Icons.location_on_outlined, required: true, maxLines: 2),
                _field(_districtCtrl, 'Kecamatan', Icons.map_outlined, required: true),
                _field(_descCtrl, 'Deskripsi', Icons.description_outlined, maxLines: 4),
              ]),
              const SizedBox(height: 16),

              // 2. Operasional
              _buildSection('Operasional & Kontak', [
                _field(_priceCtrl, 'Harga Tiket (0 = Gratis)', Icons.attach_money, keyboardType: TextInputType.number),
                Row(
                  children: [
                    Expanded(
                      child: _field(_openingHoursCtrl, 'Jam Buka (contoh: 08:00 - 17:00)', Icons.access_time_outlined,
                          enabled: !_is24Hours),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Buka 24 Jam', style: AppTextStyles.body),
                  subtitle: const Text('Aktifkan jika destinasi buka tanpa batas waktu'),
                  value: _is24Hours,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _is24Hours = v),
                ),
                _field(_csPhoneCtrl, 'Nomor WA / CS', Icons.phone_outlined, keyboardType: TextInputType.phone),
                _field(_mapsUrlCtrl, 'Link Google Maps', Icons.link_rounded),
              ]),
              const SizedBox(height: 16),

              // 3. Pilihan Fasilitas (Key: _fasilitasKey)
              Container(
                key: _fasilitasKey,
                child: _buildFacilitiesSection(),
              ),
              const SizedBox(height: 16),

              // 4. Galeri Foto Wisata (Key: _galeriKey)
              Container(
                key: _galeriKey,
                child: _buildGallerySection(),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_saving || _isDeletingImage) ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan Perubahan...' : 'Simpan Semua Perubahan'),
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
      ),
    );
  }

  // ─── Section Fasilitas ──────────────────────────────────────────────────────
  Widget _buildFacilitiesSection() {
    return _buildSection(
      'Fasilitas Tersedia',
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih fasilitas yang ada di destinasi:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedFacilityIds.length} Dipilih',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingFacilities)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_allFacilities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Tidak ada daftar fasilitas master ditemukan.', style: TextStyle(color: AppColors.textMuted)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allFacilities.map((f) {
              final id = f['id'] as int;
              final name = f['name']?.toString() ?? 'Fasilitas';
              final isSelected = _selectedFacilityIds.contains(id);
              final icon = _getFacilityIcon(name);

              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(name),
                  ],
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFacilityIds.add(id);
                    } else {
                      _selectedFacilityIds.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // ─── Section Galeri Foto ────────────────────────────────────────────────────
  Widget _buildGallerySection() {
    final totalPhotos = _existingImages.length + _newImages.length;

    return _buildSection(
      'Galeri Foto Wisata',
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kelola foto-foto galeri destinasi:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            Text(
              '$totalPhotos Foto',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List Foto Yang Sudah Ada
        if (_existingImages.isNotEmpty) ...[
          const Text(
            'Foto Saat Ini (Tersimpan):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final img = _existingImages[i];
                final url = (img['image_url'] ?? img['url'] ?? img['image_path'] ?? '').toString();

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 120,
                        height: 96,
                        color: const Color(0xFFE2E8F0),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteExistingImage(img),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: GestureDetector(
                        onTap: () => _setCover(img),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                              SizedBox(width: 3),
                              Text(
                                'Jadikan Cover',
                                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // List Foto Baru Yang Belum Diupload
        if (_newImages.isNotEmpty) ...[
          const Text(
            'Foto Baru Yang Akan Diunggah:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E6F1D)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final item = _newImages[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 120,
                        height: 96,
                        color: const Color(0xFFE2E8F0),
                        child: Image.memory(
                          item.bytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _newImages.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6F1D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BARU',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Tombol Tambah Foto
        OutlinedButton.icon(
          onPressed: _pickNewImages,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
          label: const Text('Pilih Foto Baru dari Galeri HP', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 14)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: !enabled,
          fillColor: enabled ? null : const Color(0xFFF1F5F9),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
      ),
    );
  }
}
