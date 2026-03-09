import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/content_provider.dart';
import '../../widgets/movie_card.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _searchCtrl;
  String? _selectedType;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    ref.read(searchProvider.notifier).search(
          _searchCtrl.text,
          type: _selectedType,
          year: _selectedYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: widget.initialQuery == null,
          style: const TextStyle(
              color: AppColors.textPrimary, fontFamily: 'Inter'),
          decoration: const InputDecoration(
            hintText: 'Buscar filmes e séries...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: (_) => _doSearch(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.goNamed('home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.accent),
              onPressed: _doSearch,
            ),
        ],
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(state.error!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (state.query.isNotEmpty && state.results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_outlined,
                color: AppColors.textDisabled, size: 64),
            SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Tente buscar por outro título',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return const Center(
        child: Text(
          'Digite algo para buscar...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final item = state.results[index];
        return MovieCard(
          content: item,
          onTap: () => context.pushNamed(
            'detail',
            pathParameters: {'imdbId': item.imdbId},
            extra: {'title': item.title, 'posterUrl': item.posterUrl},
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtros',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 20),
                  const Text('Tipo',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['MOVIE', 'SERIES', 'DOCUMENTARY'].map((type) {
                      final label = switch (type) {
                        'MOVIE' => 'Filme',
                        'SERIES' => 'Série',
                        'DOCUMENTARY' => 'Documentário',
                        _ => type,
                      };
                      return FilterChip(
                        label: Text(label),
                        selected: _selectedType == type,
                        onSelected: (v) => setModalState(
                            () => _selectedType = v ? type : null),
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: _selectedType == type
                              ? Colors.black
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _doSearch();
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
