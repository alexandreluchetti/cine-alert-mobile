class ContentEntity {
  final String? id;
  final String imdbId;
  final String title;
  final String type;
  final String? posterUrl;
  final int? year;
  final double? rating;
  final String? genre;
  final String? synopsis;
  final String? trailerUrl;
  final int? runtimeMinutes;

  const ContentEntity({
    this.id,
    required this.imdbId,
    required this.title,
    required this.type,
    this.posterUrl,
    this.year,
    this.rating,
    this.genre,
    this.synopsis,
    this.trailerUrl,
    this.runtimeMinutes,
  });

  List<String> get genreList =>
      genre?.split(', ').where((g) => g.isNotEmpty).toList() ?? [];

  String get ratingFormatted =>
      rating != null ? rating!.toStringAsFixed(1) : 'N/A';

  bool get isMovie => type == 'MOVIE';
  bool get isSeries => type == 'SERIES' || type == 'MINI_SERIES';
}
