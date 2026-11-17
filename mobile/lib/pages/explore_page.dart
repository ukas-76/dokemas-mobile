import 'package:flutter/material.dart';
import 'package:mobile/components/filter_bottom_sheet.dart';
import 'package:mobile/pages/detail_destinasi_screen.dart';
import '../models/category.dart';
import '../models/destination.dart';
import '../models/facility.dart';
import '../service/api_service.dart';
import '../widgets/destination_card.dart';
import '../widgets/dokemas_top_header.dart';
import 'notification_page.dart';

class ExplorePage extends StatefulWidget {
  final String? searchQuery;

  const ExplorePage({super.key, this.searchQuery});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late TextEditingController _searchController;
  String _currentQuery = '';

  String _selectedCategory = 'Semua';

  // Filter variables from Bottom Sheet
  String _selectedHarga = '';
  String _selectedJarak = '';
  String _selectedRating = '';
  List<String> _selectedFasilitas = [];

  // State for fetched categories and facilities
  List<Category> _categories = [];
  List<Facility> _facilities = [];
  bool _isLoadingFilters = true;

  late Future<List<Destination>> _futureDestinations;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery ?? '');
    _currentQuery = widget.searchQuery ?? '';
    _futureDestinations = ApiService().fetchDestinations();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final categories = await ApiService().fetchCategories();
      final facilities = await ApiService().fetchFacilities();
      if (mounted) {
        setState(() {
          _categories = categories;
          _facilities = facilities;
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    }
  }

  bool get _hasActiveFilters =>
      _currentQuery.isNotEmpty ||
      _selectedCategory != 'Semua' ||
      _selectedHarga.isNotEmpty ||
      _selectedJarak.isNotEmpty ||
      _selectedRating.isNotEmpty ||
      _selectedFasilitas.isNotEmpty;

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _selectedCategory = 'Semua';
      _selectedHarga = '';
      _selectedJarak = '';
      _selectedRating = '';
      _selectedFasilitas = [];
    });
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'semua':
        return Icons.travel_explore_rounded;
      case 'alam':
      case 'wisata alam':
        return Icons.terrain_rounded;
      case 'kuliner':
      case 'kuliner khas':
        return Icons.restaurant_rounded;
      case 'keluarga':
        return Icons.people_alt_rounded;
      case 'edukasi':
      case 'budaya & sejarah':
        return Icons.school_rounded;
      case 'religi':
        return Icons.mosque_rounded;
      default:
        return Icons.place_rounded;
    }
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
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Navy Hero Header (aligned with Beranda)
            _buildHeroSearchSection(context),
            const SizedBox(height: 16),

            // Category Pills
            _buildQuickTags(),
            const SizedBox(height: 8),

            // Grid Results from Database
            Expanded(child: _buildDestinationGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSearchSection(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (canPop)
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          Icons.arrow_back_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                        Icons.explore_rounded,
                        size: 13,
                        color: Color(0xFF4ADE80),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Eksplor Banyumas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Eksplor Destinasi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan tempat wisata alam, budaya, & kuliner terbaik',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
            ),
          ),

          const SizedBox(height: 16),

          // Rounded White Search Pill + Green Filter Circle
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
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _currentQuery = value;
                      });
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari tempat wisata, kuliner, area...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _currentQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _currentQuery = '';
                                });
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final result = await showFilterBottomSheet(
                      context,
                      initialHarga: _selectedHarga,
                      initialJarak: _selectedJarak,
                      initialRating: _selectedRating,
                      initialKategori:
                          _selectedCategory == 'Semua' ? '' : _selectedCategory,
                      initialFasilitas: List.from(_selectedFasilitas),
                      availableCategories: _categories.isNotEmpty
                          ? _categories.map((c) => c.name).toList()
                          : const [
                              'Alam',
                              'Keluarga',
                              'Kuliner',
                              'Edukasi',
                              'Religi',
                            ],
                      availableFacilities: _facilities.isNotEmpty
                          ? _facilities.map((f) => f.name).toList()
                          : const [
                              'Parkir',
                              'Toilet',
                              'Mushola',
                              'Warung',
                              'Gazebo',
                              'Spot Foto',
                              'Wahana Air',
                              'Penginapan',
                              'Wifi',
                            ],
                    );
                    if (result != null) {
                      setState(() {
                        _selectedHarga = result['harga'];
                        _selectedJarak = result['jarak'];
                        _selectedRating = result['rating'];
                        _selectedCategory = result['kategori'].isEmpty
                            ? 'Semua'
                            : result['kategori'];
                        _selectedFasilitas = result['fasilitas'];
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
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
                      if (_selectedHarga.isNotEmpty ||
                          _selectedJarak.isNotEmpty ||
                          _selectedRating.isNotEmpty ||
                          _selectedFasilitas.isNotEmpty)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags() {
    if (_isLoadingFilters) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1E6F1D),
            ),
          ),
        ),
      );
    }

    final List<String> tags = ['Semua', ..._categories.map((c) => c.name)];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = _selectedCategory == tag;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = tag;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E6F1D) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E6F1D)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
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
                    _getCategoryIcon(tag),
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF1E6F1D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
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

  Widget _buildDestinationGrid() {
    return FutureBuilder<List<Destination>>(
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
              padding: const EdgeInsets.all(20),
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

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada destinasi dari database.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        final allItems = snapshot.data!;

        // Gabungan filter query pencarian & kategori dinamis
        final filteredItems = allItems.where((item) {
          final name = item.name.toLowerCase();
          final area = item.area.toLowerCase();
          final query = _currentQuery.toLowerCase();

          bool matchesSearch = name.contains(query) || area.contains(query);
          bool matchesCategory = _selectedCategory == 'Semua' ||
              item.category.toLowerCase() == _selectedCategory.toLowerCase();

          bool matchesRating = true;
          if (_selectedRating == '★ 4.0+') {
            matchesRating = item.rating >= 4.0;
          } else if (_selectedRating == '★ 4.5+') {
            matchesRating = item.rating >= 4.5;
          }

          bool matchesHarga = true;
          if (_selectedHarga == 'Gratis') {
            matchesHarga = item.price == 0;
          } else if (_selectedHarga == '< 10k') {
            matchesHarga = item.price > 0 && item.price < 10000;
          } else if (_selectedHarga == '10k - 25k') {
            matchesHarga = item.price >= 10000 && item.price <= 25000;
          } else if (_selectedHarga == '> 25k') {
            matchesHarga = item.price > 25000;
          }

          bool matchesFasilitas = true;
          if (_selectedFasilitas.isNotEmpty) {
            final itemFasilitas = item.facilities.map((e) => e.name).toList();
            for (var fas in _selectedFasilitas) {
              if (!itemFasilitas.contains(fas)) {
                matchesFasilitas = false;
                break;
              }
            }
          }

          return matchesSearch &&
              matchesCategory &&
              matchesRating &&
              matchesHarga &&
              matchesFasilitas;
        }).toList();

        return Column(
          children: [
            // Result count & Reset filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredItems.length} Destinasi Ditemukan',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (_hasActiveFilters)
                    InkWell(
                      onTap: _resetAllFilters,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          'Reset Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E6F1D),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Grid or Empty state
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: const Color(0xFF94A3B8)
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Wisata tidak ditemukan.',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _resetAllFilters,
                                child: const Text(
                                  'Tampilkan Semua Destinasi',
                                  style: TextStyle(
                                    color: Color(0xFF1E6F1D),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF1E6F1D),
                      onRefresh: () async {
                        setState(() {
                          _futureDestinations = ApiService().fetchDestinations();
                        });
                        await _loadFilters();
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.74,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return DestinationCard(
                            destination: item,
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
                                    price: formatRupiah(item.price),
                                    distance: '-',
                                    openingHours:
                                        '${item.openHour} -\n${item.closeHour}',
                                    description: item.description.isNotEmpty
                                        ? item.description
                                        : 'Kategori: ${item.category}. Fasilitas: ${item.facilities.map((f) => f.name).join(", ")}',
                                    galleryImages: item.images
                                        .map((img) => img.imageUrl)
                                        .toList(),
                                    category: item.category,
                                    facilities: item.facilities,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
