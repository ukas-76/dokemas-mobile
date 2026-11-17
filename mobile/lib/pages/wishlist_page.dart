import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/destination.dart';
import '../providers/auth_provider.dart';
import '../providers/itinerary_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/dokemas_top_header.dart';
import '../widgets/wishlist_card.dart';
import 'detail_destinasi_screen.dart';
import 'user/itinerary/itinerary_list_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _isSearching = false;
  bool _previewEmptyState = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = 'Semua';
  String _sortBy = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWishlists();
    });
  }

  Future<void> _fetchWishlists() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<WishlistProvider>().fetchWishlist(token);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<void> _removeFavorite(Destination item) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || item.id == null) return;

    final wishlistProvider = context.read<WishlistProvider>();

    try {
      bool newStatus = await wishlistProvider.toggleWishlist(token, item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '${item.name} ditambahkan ke Wishlist'
                  : '${item.name} dihapus dari Wishlist',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: newStatus ? const Color(0xFF1E6F1D) : Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah wishlist, silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openDirections(Destination item) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(item.name)}';
    final Uri url = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka peta untuk ${item.name}')),
        );
      }
    }
  }

  Future<void> _openAddToPlanDialog(Destination item) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || item.id == null) return;

    final itineraryProvider = context.read<ItineraryProvider>();
    await itineraryProvider.fetchItineraries(token);
    if (!mounted) return;

    final itineraries = itineraryProvider.activeItineraries;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Tambah ke Rencana',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (itineraries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Belum ada itinerary, silakan buat baru.'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: itineraries.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final itinerary = itineraries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          itinerary.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          itinerary.dateRangeText,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1E6F1D),
                        ),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          final error = await itineraryProvider.addItem(
                            token,
                            itinerary.id,
                            destinationId: item.id!,
                          );
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                error ?? 'Berhasil ditambahkan ke ${itinerary.title}.',
                              ),
                              backgroundColor: error == null
                                  ? const Color(0xFF1E6F1D)
                                  : Colors.redAccent,
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const ItineraryListPage(autoOpenAddForm: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Buat Itinerary Baru',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6F1D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Urutkan Wishlist',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption('default', 'Terbaru Disimpan'),
              _buildSortOption('rating', 'Rating Tertinggi'),
              _buildSortOption('price_low', 'Harga Tiket Terendah'),
              _buildSortOption('name', 'Nama (A - Z)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String value, String label) {
    final selected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFF1E6F1D) : const Color(0xFF0F172A),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF1E6F1D))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const DokemasTopHeader(),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E6F1D)),
            );
          }

          if (provider.errorMessage != null && provider.wishlist.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchWishlists,
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

          final totalWishlist = provider.wishlist.length;
          final alamCount = provider.wishlist
              .where((e) => e.category.toLowerCase() == 'alam')
              .length;
          final kulinerCount = provider.wishlist
              .where((e) => e.category.toLowerCase() == 'kuliner')
              .length;
          final edukasiCount = provider.wishlist
              .where((e) => e.category.toLowerCase() == 'edukasi')
              .length;
          final keluargaCount = provider.wishlist
              .where((e) => e.category.toLowerCase() == 'keluarga')
              .length;

          final List<Map<String, dynamic>> categoryTabs = [
            {'key': 'Semua', 'label': 'Semua', 'count': totalWishlist, 'icon': null},
            {'key': 'Alam', 'label': 'Wisata Alam', 'count': alamCount, 'icon': Icons.terrain_rounded},
            {'key': 'Kuliner', 'label': 'Kuliner', 'count': kulinerCount, 'icon': Icons.restaurant_rounded},
            if (keluargaCount > 0)
              {'key': 'Keluarga', 'label': 'Keluarga', 'count': keluargaCount, 'icon': Icons.people_rounded},
            if (edukasiCount > 0)
              {'key': 'Edukasi', 'label': 'Edukasi', 'count': edukasiCount, 'icon': Icons.school_rounded},
          ];

          List<Destination> filteredWishlist = provider.wishlist.where((item) {
            final matchesSearch = _searchQuery.isEmpty ||
                item.name.toLowerCase().contains(_searchQuery) ||
                item.category.toLowerCase().contains(_searchQuery) ||
                item.area.toLowerCase().contains(_searchQuery);
            final matchesCategory = _selectedCategory == 'Semua' ||
                item.category.toLowerCase() == _selectedCategory.toLowerCase();
            return matchesSearch && matchesCategory;
          }).toList();

          if (_sortBy == 'rating') {
            filteredWishlist.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (_sortBy == 'price_low') {
            filteredWishlist.sort((a, b) => a.price.compareTo(b.price));
          } else if (_sortBy == 'name') {
            filteredWishlist.sort((a, b) => a.name.compareTo(b.name));
          }

          return Column(
            children: [
              // Header Title + Search + Urutkan
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wishlist Saya',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Destinasi Impian di Banyumas',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$totalWishlist Tempat',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E6F1D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_isSearching) {
                                    _isSearching = false;
                                    _searchController.clear();
                                    _searchQuery = "";
                                  } else {
                                    _isSearching = true;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF4FA),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isSearching ? Icons.close : Icons.search_rounded,
                                  size: 20,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _showSortOptions,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sort_rounded,
                                      size: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Urutkan',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (_isSearching) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _filterSearch,
                          decoration: const InputDecoration(
                            hintText: 'Cari nama tempat atau lokasi...',
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            icon: Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Category Pills
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryTabs.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = categoryTabs[index];
                    final key = tab['key'] as String;
                    final label = tab['label'] as String;
                    final count = tab['count'] as int;
                    final icon = tab['icon'] as IconData?;
                    final isActive = _selectedCategory == key;

                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = key),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF071B34) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF071B34)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: 15,
                                color: isActive ? Colors.white : const Color(0xFF1E6F1D),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Swipe Hint Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swipe_left_outlined,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Geser kartu ke kiri untuk menghapus atau klik ikon hati.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() => _previewEmptyState = !_previewEmptyState);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _previewEmptyState ? 'Tampilkan' : 'Mode Kosong',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _previewEmptyState
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // List or Empty State
              Expanded(
                child: (_previewEmptyState || filteredWishlist.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 68,
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Belum ada destinasi favorit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Silakan jelajahi tempat-tempat menarik dan tekan ikon hati untuk menyimpannya di sini.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF1E6F1D),
                        onRefresh: _fetchWishlists,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filteredWishlist.length,
                          itemBuilder: (context, index) {
                            final item = filteredWishlist[index];
                            final priceStr = item.price == 0
                                ? 'Gratis'
                                : formatRupiah(item.price);

                            return Dismissible(
                              key: ValueKey('dismiss_${item.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB91C1C),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (_) => _removeFavorite(item),
                              child: WishlistCard(
                                key: ValueKey(item.id),
                                title: item.name,
                                category: item.category,
                                location: item.area,
                                rating: item.rating,
                                reviewCount: item.reviews,
                                priceText: priceStr,
                                openingHours: '${item.openHour} - ${item.closeHour}',
                                imageUrl: item.imageUrl,
                                isFavorite: true,
                                onFavoritePressed: () => _removeFavorite(item),
                                onAddToPlanPressed: () => _openAddToPlanDialog(item),
                                onDirectionsPressed: () => _openDirections(item),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailDestinasiScreen(
                                        destinationId: item.id ?? 0,
                                        title: item.name,
                                        imageUrl: item.imageUrl,
                                        rating: item.rating.toString(),
                                        reviewCount: '${item.reviews} ulasan',
                                        location: item.area,
                                        price: priceStr,
                                        distance: '14 km',
                                        openingHours:
                                            '${item.openHour} -\n${item.closeHour}',
                                        description: item.description.isNotEmpty
                                            ? item.description
                                            : 'Nikmati keindahan pesona destinasi wisata terbaik di Banyumas.',
                                        galleryImages: item.images
                                            .map((img) => img.imageUrl)
                                            .toList(),
                                        category: item.category,
                                        facilities: item.facilities,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
