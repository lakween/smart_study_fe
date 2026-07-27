import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';

  static const String productionBaseUrl =
      'https://84.247.138.71/smart-study';

  /// Backend base URL. Release builds use [productionBaseUrl]. Debug and
  /// profile builds use the appropriate localhost alias for local development.
  /// Override either behavior with `--dart-define=API_BASE_URL=<url>`.
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) return productionBaseUrl;
    if (kIsWeb) return 'https://84.247.138.71/smart-study';
    if (Platform.isAndroid) return 'https://84.247.138.71/smart-study';
    return 'https://84.247.138.71/smart-study';
  }

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String darkModeKey = 'dark_mode';
  static const String fontSizeKey = 'font_size';
  static const String defaultVisibilityKey = 'default_visibility';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Validation
  static const int minNameLength = 2;
  static const int maxSubjectNameLength = 100;
  static const int minPasswordLength = 8;
  static const int minQuizTitleLength = 3;
  static const int minQuestionLength = 5;
  static const int maxFileSizeMB = 10;

  // Spaced Repetition (days)
  static const List<int> spacedRepetitionDays = [1, 3, 7, 14, 30];

  // Quiz
  static const int passThreshold = 60;
  static const List<int> questionCountOptions = [5, 10, 15, 20];
  static const List<int> durationOptions = [15, 30, 45, 60, 90, 120];

  // Supported file types
  static const List<String> supportedFileExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  // Pagination
  static const int pageSize = 20;
}
