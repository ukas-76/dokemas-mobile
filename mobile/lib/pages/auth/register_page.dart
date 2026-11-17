import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dokemas_logo.dart';
import '../main_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan serta Kebijakan Privasi DOKEMAS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      // Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E6F1D)),
        ),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final errorMessage = await authProvider.register(name, email, password, confirmPassword);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup Loading

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran sukses!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1;
    if (password.length < 8) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E6F1D);
    const inputFillColor = Color(0xFFF6F8FC);
    const borderColor = Color(0xFFE2E8F0);
    final strength = _calculatePasswordStrength();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          'Register',
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
              child: DokemasLogo(
                width: 28,
                height: 28,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Top Dokemas Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2FE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DokemasLogo(
                        width: 18,
                        height: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DOKEMAS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0xFF0F2444),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Headline & Subtitle
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mulai eksplorasi wisata dan hotel di\nBanyumas.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Input Nama Lengkap
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Siti Rahmawati',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Input Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'alamat@email.com',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Input Kata Sandi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kata Sandi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter',
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    if (value.length < 8) {
                      return 'Kata sandi minimal 8 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Password Strength Indicator Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: strength >= 1
                              ? (strength == 1 ? Colors.orange : const Color(0xFF22C55E))
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: strength >= 2
                              ? (strength == 2 ? Colors.orange : const Color(0xFF22C55E))
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: strength >= 3
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sandi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Input Konfirmasi Kata Sandi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Konfirmasi Kata Sandi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(
                      Icons.replay_rounded,
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
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
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

                const SizedBox(height: 16),

                // Terms & Conditions Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: borderColor, width: 1.5),
                        onChanged: (val) {
                          setState(() => _agreeToTerms = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _agreeToTerms = !_agreeToTerms);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(text: 'Saya setuju dengan '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              TextSpan(text: ' DOKEMAS.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Primary Button ("Daftar Akun ->")
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 3,
                      shadowColor: primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Daftar Akun',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Divider ("ATAU DAFTAR DENGAN")
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: borderColor, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'ATAU DAFTAR DENGAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: borderColor, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Social Buttons (Google & Apple)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Simulasi Registrasi via Google...'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: inputFillColor,
                            side: const BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                  children: [
                                    TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                                    TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                                    TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                                    TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                                    TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                                    TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Simulasi Registrasi via Apple...'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: inputFillColor,
                            side: const BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apple,
                                size: 20,
                                color: Color(0xFF0F172A),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Apple',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // Back to Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Masuk di sini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
