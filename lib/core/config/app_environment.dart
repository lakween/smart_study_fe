import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppEnvironment {
  AppEnvironment._();

  static const String productionUrl = 'https://84.247.138.71/smart-study';

  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String _urlOverride = String.fromEnvironment('API_BASE_URL');

  static bool get isProduction => _environment.toLowerCase() == 'production';

  static String get baseUrl {
    if (_urlOverride.isNotEmpty) return _urlOverride;
    if (isProduction) return productionUrl;
    if (kIsWeb) return 'http://localhost:4000';
    if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }
}
