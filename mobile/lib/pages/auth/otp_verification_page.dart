import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dokemas_logo.dart';
import 'reset_password_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.verifyOtp(widget.email, _otpController.text.trim());

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (error == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              email: widget.email,
              otp: _otpController.text.trim(),
            ),
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

  Future<void> _handleResendOtp() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.forgotPassword(widget.email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP telah dikirim ulang ke email Anda.'),
          backgroundColor: Color(0xFF16A34A),
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
          'Verifikasi OTP',
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
                    Icons.pin_outlined,
                    color: primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Masukkan Kode OTP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan 6 digit kode OTP yang telah dikirim ke\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kode OTP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      letterSpacing: 10,
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                      return 'OTP tidak boleh kosong';
                    }
                    if (value.length != 6) {
                      return 'OTP harus 6 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyOtp,
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
                            'Verifikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: _isLoading ? null : _handleResendOtp,
                  child: const Text(
                    'Kirim Ulang OTP',
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
