import 'package:flutter/material.dart';
import 'beranda.dart';
import 'explore_page.dart';
import 'guest/guest_wishlist_page.dart';
import 'guest/guest_itinerary_page.dart';
import 'guest/guest_profile_page.dart';

/// Shell untuk user BELUM login.
/// Home & Explore bebas; Wishlist/Itinerary/Profile ke-gate (harus login).
class GuestMainScreen extends StatefulWidget {
  const GuestMainScreen({super.key});

  @override
  State<GuestMainScreen> createState() => _GuestMainScreenState();
}

class _GuestMainScreenState extends State<GuestMainScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
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
