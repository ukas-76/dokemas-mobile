import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';

class MitraEditDestinasiPage extends StatefulWidget {
  final MitraDestinationSummary destination;
  const MitraEditDestinasiPage({super.key, required this.destination});

  @override
  State<MitraEditDestinasiPage> createState() => _MitraEditDestinasiPageState();
}

class _MitraEditDestinasiPageState extends State<MitraEditDestinasiPage> {
  final _formKey = GlobalKey<FormState>();
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
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final fields = {
      'destination_name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'opening_hours': _openingHoursCtrl.text.trim(),
      'cs_phone': _csPhoneCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'maps_url': _mapsUrlCtrl.text.trim(),
      'is_24_hours': _is24Hours ? '1' : '0',
    };

    final prov = context.read<MitraProvider>();
    final error = await prov.updateDestination(
      destinationId: widget.destination.id,
      fields: fields,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Data destinasi berhasil diperbarui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection('Informasi Utama', [
                _field(_nameCtrl, 'Nama Destinasi', Icons.label_outline, required: true),
                _field(_addressCtrl, 'Alamat Lengkap', Icons.location_on_outlined, required: true, maxLines: 2),
                _field(_districtCtrl, 'Kecamatan', Icons.map_outlined, required: true),
                _field(_descCtrl, 'Deskripsi', Icons.description_outlined, maxLines: 4),
              ]),
              const SizedBox(height: 16),
              _buildSection('Operasional', [
                _field(_priceCtrl, 'Harga Tiket (0 = Gratis)', Icons.attach_money, keyboardType: TextInputType.number),
                Row(
                  children: [
                    Expanded(
                      child: _field(_openingHoursCtrl, 'Jam Buka (08:00 - 17:00)', Icons.access_time_outlined,
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
              ]),
              const SizedBox(height: 16),
              _buildSection('Lokasi', [
                _field(_mapsUrlCtrl, 'Link Google Maps', Icons.link_rounded),
              ]),
              const SizedBox(height: 20),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
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
