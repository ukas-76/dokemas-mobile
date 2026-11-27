import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/mitra_provider.dart';
import 'dashboard/mitra_dashboard_page.dart';
import 'destinasi/mitra_destinasi_page.dart';
import 'ulasan/mitra_ulasan_page.dart';
import 'profil/mitra_profil_page.dart';
import '../chat/chat_list_page.dart';

class MitraShell extends StatefulWidget {
  const MitraShell({super.key});

  @override
  State<MitraShell> createState() => _MitraShellState();
}

class _MitraShellState extends State<MitraShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard Mitra',
    'Destinasi Saya',
    'Pesan Masuk',
    'Ulasan Pengunjung',
    'Profil Mitra',
  ];

  late final List<Widget> _pages = [
    MitraDashboardPage(onNavigateToDestinasi: () => setState(() => _index = 1)),
    const MitraDestinasiPage(),
    const ChatListPage(),
    const MitraUlasanPage(),
    const MitraProfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Langsung fetch data status mitra saat shell dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MitraProvider>().fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MITRA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _titles[_index],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 0) {
            context.read<MitraProvider>().fetchStatus();
          } else if (i == 3) {
            context.read<MitraProvider>().fetchReviews();
          }
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded, color: AppColors.primary),
            label: 'Destinasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
            label: 'Pesan',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review_rounded, color: AppColors.primary),
            label: 'Ulasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
