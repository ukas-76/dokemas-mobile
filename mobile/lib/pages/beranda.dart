import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/filter_bottom_sheet.dart';
import '../models/destination.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../service/api_service.dart';
import '../widgets/dokemas_top_header.dart';
import 'auth/login_page.dart';
import 'detail_destinasi_screen.dart';
import 'explore_page.dart';
import 'notification_page.dart';

// Fungsi helper untuk memformat angka menjadi Rupiah dinamis
String formatRupiah(int price) {
  return 'Rp ${price.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';
}

class HomePage extends StatefulWidget {
  final void Function(int)? onTabChanged;
  const HomePage({super.key, this.onTabChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'Semua';

  late Future<List<Destination>> _futureDestinations;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'Semua', 'label': 'Semua', 'icon': Icons.travel_explore_rounded},
    {'key': 'Alam', 'label': 'Wisata Alam', 'icon': Icons.terrain_rounded},
    {'key': 'Kuliner', 'label': 'Kuliner Khas', 'icon': Icons.restaurant_rounded},
    {'key': 'Keluarga', 'label': 'Keluarga', 'icon': Icons.people_alt_rounded},
    {'key': 'Edukasi', 'label': 'Edukasi', 'icon': Icons.school_rounded},
    {'key': 'Religi', 'label': 'Religi', 'icon': Icons.mosque_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _futureDestinations = ApiService().fetchDestinations();
  }

  Future<void> _handleToggleFavorite(Destination destination) async {
    if (destination.id == null) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silahkan login terlebih dahulu untuk menyimpan ke wishlist'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    final wishlistProvider = context.read<WishlistProvider>();
    try {
      final newStatus = await wishlistProvider.toggleWishlist(token, destination.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '${destination.name} ditambahkan ke Wishlist'
                : '${destination.name} dihapus dari Wishlist',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? const Color(0xFF1E6F1D) : Colors.grey[800],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah wishlist, silakan coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openDetail(Destination destination, {String distance = '14 km'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDestinasiScreen(
          destinationId: destination.id ?? 0,
          title: destination.name,
          imageUrl: destination.imageUrl,
          rating: destination.rating.toString(),
          reviewCount: '${destination.reviews} ulasan',
          location: destination.area,
          price: formatRupiah(destination.price),
          distance: distance,
          openingHours: '${destination.openHour} -\n${destination.closeHour}',
          description: destination.description.isNotEmpty
              ? destination.description
              : 'Nikmati keindahan pesona destinasi wisata terbaik di Banyumas.',
          galleryImages: destination.images.map((img) => img.imageUrl).toList(),
          category: destination.category,
          facilities: destination.facilities,
        ),
      ),
    );
  }

  void _showAllCategoriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seluruh Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                final key = item['key'] as String;
                final isActive = _selectedCategory == key;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = key;
                    });
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1E6F1D)
                              : const Color(0xFF1E6F1D).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF1E6F1D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFF1E6F1D)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: DokemasTopHeader(
        onAvatarTap: () => widget.onTabChanged?.call(4),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Destination>>(
          future: _futureDestinations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E6F1D)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gagal memuat data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _futureDestinations = ApiService().fetchDestinations();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6F1D),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allDestinations = snapshot.data ?? [];
            final filteredDestinations = _selectedCategory == 'Semua'
                ? allDestinations
                : allDestinations.where((destination) {
                    return destination.category.toLowerCase() ==
                        _selectedCategory.toLowerCase();
                  }).toList();

            final featuredList = filteredDestinations.take(5).toList();
            final popularList = filteredDestinations.length > 1
                ? filteredDestinations.skip(1).take(6).toList()
                : filteredDestinations;

            return RefreshIndicator(
              color: const Color(0xFF1E6F1D),
              onRefresh: () async {
                setState(() {
                  _futureDestinations = ApiService().fetchDestinations();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dark Navy Hero Banner
                    _buildHeroBanner(context),
                    const SizedBox(height: 16),

                    // 2. Category Chips Row
                    _buildCategoryPills(),
                    const SizedBox(height: 22),

                    // 3. Destinasi Unggulan Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destinasi Unggulan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pilihan istimewa di kaki Gunung Slamet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onTabChanged?.call(1),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E6F1D),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: Color(0xFF1E6F1D),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFeaturedCarousel(featuredList),
                    const SizedBox(height: 22),

                    // 4. Culinary Highlight Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildCulinaryBanner(),
                    ),
                    const SizedBox(height: 24),

                    // 5. Destinasi Terpopuler Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destinasi Terpopuler',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Favorit pelancong pekan ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => showFilterBottomSheet(context),
                            icon: const Icon(
                              Icons.sort_rounded,
                              color: Color(0xFF0F172A),
                            ),
                            tooltip: 'Filter & Urutkan',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Popular Destinations 2-Column Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPopularGrid(popularList),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061B34),
            Color(0xFF0A2748),
            Color(0xFF051529),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top location pill & notification button inside hero
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _showAllCategoriesDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 13,
                        color: Color(0xFF4ADE80),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Purwokerto, Banyumas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'Halo, Mau Kemana Hari Ini?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jelajahi pesona alam, sejarah, & kuliner Banyumas',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
            ),
          ),

          const SizedBox(height: 18),

          // Rounded White Search Bar with Green Filter Circle
          Container(
            height: 50,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExplorePage(
                              searchQuery: query.trim(),
                            ),
                          ),
                        );
                      }
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari destinasi, kuliner, air terjun...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => showFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E6F1D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final key = item['key'] as String;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isActive = _selectedCategory == key;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = key;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1E6F1D) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF1E6F1D)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E6F1D).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? Colors.white : const Color(0xFF1E6F1D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<Destination> destinations) {
    if (destinations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Text(
              'Tidak ada destinasi unggulan untuk kategori ini.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 274,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return _buildFeaturedCard(destination, index);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(Destination destination, int index) {
    final distanceText = '${14 + (index * 2)} km';

    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isWishlisted = destination.id != null &&
            wishlistProvider.isWishlisted(destination.id!);

        return GestureDetector(
          onTap: () => _openDetail(destination, distance: distanceText),
          child: Container(
            width: 268,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        destination.imageUrl,
                        height: 148,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 148,
                            color: const Color(0xFFE2E8F0),
                            child: const Center(
                              child: Icon(
                                Icons.landscape_rounded,
                                size: 40,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Distance badge top-left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061B34).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF4ADE80),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Wishlist heart top-right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _handleToggleFavorite(destination),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isWishlisted
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF334155),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    destination.area,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFF16A34A),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${destination.rating.toStringAsFixed(1)} (${destination.reviews})',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        // Bottom Price & Detail Pill Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Tiket Masuk',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: destination.price == 0
                                            ? 'Gratis'
                                            : formatRupiah(destination.price),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (destination.price > 0)
                                        const TextSpan(
                                          text: ' /org',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF071B34),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Detail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCulinaryBanner() {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = 'Kuliner';
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF071B34),
              Color(0xFF0B2C52),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071B34).withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.ramen_dining_rounded,
                color: Color(0xFF4ADE80),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CITA RASA KHAS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Mendoan Anget & Kopi Banyumas',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rekomendasi warung otentik di sekitar Anda',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularGrid(List<Destination> destinations) {
    if (destinations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'Tidak ada data destinasi populer untuk kategori ini.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return _buildPopularGridCard(destination);
      },
    );
  }

  Widget _buildPopularGridCard(Destination destination) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isWishlisted = destination.id != null &&
            wishlistProvider.isWishlisted(destination.id!);

        return GestureDetector(
          onTap: () => _openDetail(destination, distance: '5 km'),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image with rating & favorite
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        destination.imageUrl,
                        height: 118,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 118,
                            color: const Color(0xFFE2E8F0),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Top-right favorite circle
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _handleToggleFavorite(destination),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isWishlisted
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF334155),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Bottom-left dark rating badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFF4ADE80),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              destination.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Color(0xFF1E6F1D),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    destination.area,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                destination.price == 0
                                    ? destination.category
                                    : formatRupiah(destination.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: destination.price == 0
                                      ? const Color(0xFF1E6F1D)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              destination.price == 0 ? 'Otentik' : '/org',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
