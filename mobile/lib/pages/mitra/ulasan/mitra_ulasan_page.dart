import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../providers/mitra_provider.dart';

class MitraUlasanPage extends StatefulWidget {
  const MitraUlasanPage({super.key});

  @override
  State<MitraUlasanPage> createState() => _MitraUlasanPageState();
}

class _MitraUlasanPageState extends State<MitraUlasanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MitraProvider>().fetchReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MitraProvider>(
      builder: (context, prov, _) {
        final reviews = prov.reviews;

        // Header rata-rata
        final double avgRating = reviews.isEmpty
            ? 0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => prov.fetchReviews(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header rata-rata rating
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF061B34), Color(0xFF0A2748)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Rating besar
                      Column(
                        children: [
                          Text(
                            avgRating == 0 ? '-' : avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text('dari 5', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Bintang + jumlah
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StarRow(rating: avgRating),
                            const SizedBox(height: 8),
                            Text(
                              '${reviews.length} ulasan masuk',
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reviews.isEmpty ? 'Belum ada ulasan' : 'Rating destinasi Anda',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading / Error / List
              if (prov.isReviewLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (prov.reviewError != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(prov.reviewError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => prov.fetchReviews(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (reviews.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 56, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Belum ada ulasan', style: AppTextStyles.title),
                        SizedBox(height: 6),
                        Text(
                          'Ulasan wisatawan akan muncul di sini.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ReviewCard(review: reviews[i]),
                      childCount: reviews.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half ? Icons.star_half_rounded : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          color: const Color(0xFFF59E0B),
          size: 20,
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final MitraReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.reviewerAvatar != null
                    ? NetworkImage(review.reviewerAvatar!)
                    : null,
                child: review.reviewerAvatar == null
                    ? Text(
                        review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'W',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(dateStr, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _StarBadge(rating: review.rating),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _StarBadge extends StatelessWidget {
  final double rating;
  const _StarBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B))),
        ],
      ),
    );
  }
}
