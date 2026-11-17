import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../pages/auth/login_page.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });

  Future<void> _handleToggleFavorite(BuildContext context) async {
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
      if (!context.mounted) return;
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah wishlist, silakan coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isWishlisted =
            destination.id != null && wishlistProvider.isWishlisted(destination.id!);

        return GestureDetector(
          onTap: onTap,
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
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.network(
                          destination.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top-right favorite circle
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _handleToggleFavorite(context),
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
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
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
                      const SizedBox(height: 8),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
