class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.cinealert.link',
  );

  static const String apiPrefix = '/api';

  // Hive boxes
  static const String tokenBox = 'tokens';
  static const String contentBox = 'content';
  static const String userBox = 'user';

  // Hive keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';

  // Durations
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Pagination
  static const int pageSize = 20;

  // Validation
  static const int maxMessageLength = 255;
  static const int minPasswordLength = 6;
}
