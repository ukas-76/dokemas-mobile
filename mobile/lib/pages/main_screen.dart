import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import 'admin/admin_shell.dart';
import 'mitra/mitra_shell.dart';
import 'beranda.dart';
import 'explore_page.dart';
import 'guest/guest_itinerary_page.dart';
import 'guest/guest_profile_page.dart';
import 'guest/guest_wishlist_page.dart';
import 'user/itinerary/itinerary_list_page.dart';
import 'user/profile/profile_page.dart';
import 'wishlist_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<WishlistProvider>().fetchWishlist(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isLoggedIn = authProvider.isLoggedIn;
    final String? role = authProvider.user?.role;

    // Jika sedang login sebagai Mitra atau Admin, langsung tampilkan Shell masing-masing
    if (isLoggedIn) {
      if (role == 'mitra') {
        return const MitraShell();
      } else if (role == 'admin') {
        return const AdminShell();
      }
    }

    final List<Widget> pages = isLoggedIn
        ? [
            HomePage(onTabChanged: _switchTab),
            const ExplorePage(),
            const WishlistPage(),
            const ItineraryListPage(),
            const ProfilePage(),
          ]
        : [
            HomePage(onTabChanged: _switchTab),
            const ExplorePage(),
            const GuestWishlistPage(),
            const GuestItineraryPage(),
            const GuestProfilePage(),
          ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF1E6F1D),
          unselectedItemColor: const Color(0xFF64748B),
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
          currentIndex: _currentIndex,
          onTap: _switchTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Eksplor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Favorit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Rencana',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
