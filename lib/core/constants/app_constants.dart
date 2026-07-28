import '../config/app_environment.dart';

class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';

  static String get baseUrl => AppEnvironment.baseUrl;

  static String get socketUrl {
    final uri = Uri.parse(baseUrl);
    return Uri(
            scheme: uri.scheme,
            host: uri.host,
            port: uri.hasPort ? uri.port : null)
        .toString();
  }

  static String get socketPath {
    final path = Uri.parse(baseUrl).path.replaceAll(RegExp(r'/+$'), '');
    return path.isEmpty ? '/socket.io' : '$path/socket.io';
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
  static const List<String> supportedFileExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png'
  ];

  // Pagination
  static const int pageSize = 20;
}
