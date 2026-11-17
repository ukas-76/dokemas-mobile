import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import 'dokemas_top_header.dart';

/// Konten "harus login" buat tab guest yang ke-gate (wishlist/itinerary/profile).
/// Navbar disediakan oleh shell (MainScreen/GuestMainScreen), bukan di sini.
class GuestLoginRequiredPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const GuestLoginRequiredPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E6F1D);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DokemasTopHeader(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 42,
                          color: primaryGreen,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF071B34),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF4ADE80),
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _openLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: primaryGreen.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openRegister(context),
                        child: const Text(
                          'Daftar sekarang',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
