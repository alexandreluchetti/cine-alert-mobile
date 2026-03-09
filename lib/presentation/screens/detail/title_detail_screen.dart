import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/content_entity.dart';
import '../../providers/content_provider.dart';
import 'schedule_reminder_sheet.dart';

class TitleDetailScreen extends ConsumerWidget {
  final String imdbId;
  final Map<String, dynamic>? heroData;

  const TitleDetailScreen({super.key, required this.imdbId, this.heroData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentDetailProvider(imdbId));

    // Use hero data for instant preview while loading
    final previewTitle = heroData?['title'] as String?;
    final previewPoster = heroData?['posterUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: contentAsync.when(
        data: (content) => _buildContent(context, ref, content),
        loading: () => _buildLoading(context, previewTitle, previewPoster),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ContentEntity content) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (content.posterUrl != null)
                      CachedNetworkImage(
                          imageUrl: content.posterUrl!, fit: BoxFit.cover)
                    else
                      Container(color: AppColors.surface),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withOpacity(0.7),
                            AppColors.background,
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      content.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meta row
                    Row(
                      children: [
                        if (content.year != null) ...[
                          Text('${content.year}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(width: 12),
                        ],
                        if (content.runtimeMinutes != null) ...[
                          const Icon(Icons.access_time,
                              color: AppColors.textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text('${content.runtimeMinutes} min',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          const SizedBox(width: 12),
                        ],
                        if (content.rating != null && content.rating! > 0) ...[
                          const Icon(Icons.star,
                              color: AppColors.accent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            content.ratingFormatted,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Genre chips
                    if (content.genreList.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: content.genreList
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppColors.divider),
                                  ),
                                  child: Text(g,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      )),
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 20),

                    // Synopsis
                    if (content.synopsis != null) ...[
                      const Text(
                        'Sinopse',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ExpandableSynopsis(synopsis: content.synopsis!),
                      const SizedBox(height: 20),
                    ],

                    // Trailer button
                    if (content.trailerUrl != null)
                      OutlinedButton.icon(
                        onPressed: () => _openTrailer(content.trailerUrl!),
                        icon: const Icon(Icons.play_circle_outline,
                            color: AppColors.accent),
                        label: const Text('Ver Trailer',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // FAB — Schedule reminder
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showScheduleSheet(context, ref, content),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text(
              'Lembrete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context, String? title, String? posterUrl) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: posterUrl != null
                ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover)
                : Container(color: AppColors.surface),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      )),
                const SizedBox(height: 24),
                const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Erro ao carregar: $error',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showScheduleSheet(
      BuildContext context, WidgetRef ref, ContentEntity content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleReminderSheet(content: content),
    );
  }

  void _openTrailer(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ExpandableSynopsis extends StatefulWidget {
  final String synopsis;

  const _ExpandableSynopsis({required this.synopsis});

  @override
  State<_ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<_ExpandableSynopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.synopsis,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Ver menos' : 'Ver mais',
            style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ),
      ],
    );
  }
}
