import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dokemas_logo.dart';
import 'main_screen.dart';
import 'admin/admin_shell.dart' as admin_shell;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Jalankan timer minimal 2 detik untuk efek splash
    final timer = Future.delayed(const Duration(seconds: 2));

    // Bersamaan dengan itu, cek status login
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();

    // Tunggu timer selesai
    await timer;

    if (!mounted) return;

    // Cek apakah admin atau user biasa
    if (authProvider.isLoggedIn && authProvider.user?.role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const admin_shell.AdminShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF071B34),
                    Color(0xFF092343),
                    Color(0xFF061426),
                  ],
                ),
              ),
            ),
          ),

          // Topographic Wave Lines
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveContourPainter(),
            ),
          ),

          // Main Content
          SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Frosted Glassmorphism Logo Card
                  Container(
                    width: 136,
                    height: 136,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: DokemasLogo(
                        width: 76,
                        height: 76,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Brand Title
                  const Text(
                    'DOKEMAS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4.0,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'DOLAN KELILING BANYUMAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Official Tour Guide Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glowing Green Dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PANDUAN WISATA RESMI BANYUMAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Color(0xFF86EFAC),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Glowing Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(),
                      const SizedBox(width: 8),
                      _buildDot(),
                      const SizedBox(width: 8),
                      _buildDot(),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Version Text
                  const Text(
                    'VERSI 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.85),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _WaveContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final width = size.width;
    final height = size.height;

    final yOffsets = [
      height * 0.12,
      height * 0.22,
      height * 0.34,
      height * 0.52,
      height * 0.65,
      height * 0.78,
      height * 0.88,
    ];

    for (int i = 0; i < yOffsets.length; i++) {
      final path = Path();
      final y = yOffsets[i];
      final direction = (i % 2 == 0) ? 1.0 : -1.0;

      path.moveTo(0, y);
      path.cubicTo(
        width * 0.3,
        y - 28 * direction,
        width * 0.7,
        y + 28 * direction,
        width,
        y - 10 * direction,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
