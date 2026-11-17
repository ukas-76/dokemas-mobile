import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dokemas_logo.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendInstructions() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final error = await authProvider.forgotPassword(email);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(email: email),
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
          'Lupa Kata Sandi',
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
                    Icons.lock_reset_rounded,
                    color: primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Pulihkan Kata Sandi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan alamat email Anda untuk menerima\nkode OTP pemulihan kata sandi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
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
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendInstructions,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Kirim Instruksi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '← Kembali ke Login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
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
