import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/content_entity.dart';

class MovieCard extends StatelessWidget {
  final ContentEntity content;
  final VoidCallback? onTap;
  final bool showType;

  const MovieCard({
    super.key,
    required this.content,
    this.onTap,
    this.showType = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPoster(),
                  if (showType)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (content.year != null) ...[
                        Text(
                          '${content.year}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (content.rating != null && content.rating! > 0) ...[
                        const Icon(Icons.star, color: AppColors.accent, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          content.ratingFormatted,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildPoster() {
    if (content.posterUrl != null && content.posterUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: content.posterUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _posterShimmer(),
        errorWidget: (context, url, error) => _posterPlaceholder(),
      );
    }
    return _posterPlaceholder();
  }

  Widget _posterShimmer() {
    return Container(
      color: AppColors.shimmer,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: AppColors.textDisabled, size: 40),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: AppColors.textDisabled, size: 40),
      ),
    );
  }

  String get _typeLabel => switch (content.type) {
    'MOVIE' => 'FILME',
    'SERIES' => 'SÉRIE',
    'MINI_SERIES' => 'MINI-SÉRIE',
    'DOCUMENTARY' => 'DOC',
    _ => 'FILME',
  };
}
