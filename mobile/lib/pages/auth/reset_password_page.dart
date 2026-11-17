import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dokemas_logo.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.resetPassword(
        widget.email,
        widget.otp,
        _passwordController.text,
        _confirmPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (error == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text('Berhasil'),
              ],
            ),
            content: const Text(
              'Kata sandi Anda telah berhasil direset. Silakan login kembali menggunakan kata sandi baru Anda.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Ke Halaman Login',
                  style: TextStyle(
                    color: Color(0xFF1E6F1D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E6F1D);
    const inputFillColor = Color(0xFFF6F8FC);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Reset Kata Sandi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: DokemasLogo(width: 28, height: 28),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Buat Kata Sandi Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan masukkan kata sandi baru untuk akun Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kata Sandi Baru',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi baru',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Konfirmasi Kata Sandi Baru',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi baru',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(
                      Icons.gpp_good_outlined,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong';
                    }
                    if (value != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 3,
                      shadowColor: primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Kata Sandi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
