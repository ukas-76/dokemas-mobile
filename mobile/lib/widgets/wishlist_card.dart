import 'package:flutter/material.dart';

/// Card widget untuk menampilkan destinasi favorit (wishlist) sesuai desain DOKEMAS.
class WishlistCard extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final double rating;
  final int reviewCount;
  final String priceText;
  final String openingHours;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onAddToPlanPressed;
  final VoidCallback? onDirectionsPressed;
  final VoidCallback? onTap;

  const WishlistCard({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.rating,
    this.reviewCount = 0,
    this.priceText = '',
    this.openingHours = '',
    required this.imageUrl,
    this.isFavorite = true,
    this.onFavoritePressed,
    this.onAddToPlanPressed,
    this.onDirectionsPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Top section: Thumbnail + Info + Heart button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Square Thumbnail with bottom tag
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imageUrl,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 88,
                                height: 88,
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF94A3B8),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category pill + rating + heart
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  reviewCount > 0
                                      ? '${rating.toStringAsFixed(1)} ($reviewCount)'
                                      : rating.toStringAsFixed(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onFavoritePressed,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF94A3B8),
                                    size: 21,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Title
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 13,
                                color: Color(0xFF1E6F1D),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Price + Open status
                          Row(
                            children: [
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (priceText != 'Gratis' &&
                                  priceText.isNotEmpty) ...[
                                const Text(
                                  ' /org',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              if (openingHours.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Buka $openingHours',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom action row: Tambah ke Rencana + Directions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextButton.icon(
                          onPressed: onAddToPlanPressed,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF4FA),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 17,
                            color: Color(0xFF0F172A),
                          ),
                          label: const Text(
                            'Tambah ke Rencana',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 42,
                      height: 38,
                      child: IconButton(
                        onPressed: onDirectionsPressed,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF4FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.turn_right_rounded,
                          size: 19,
                          color: Color(0xFF0F172A),
                        ),
                        tooltip: 'Petunjuk Arah',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
