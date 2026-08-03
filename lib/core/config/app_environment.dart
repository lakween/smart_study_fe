import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppEnvironment {
  AppEnvironment._();

  static const String productionUrl = 'https://chatbot.kadaima.com/smart-study';

  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String _urlOverride = String.fromEnvironment('API_BASE_URL');

  // Release builds must never silently fall back to a loopback development
  // server. API_BASE_URL can still override this for staging or self-hosting.
  static bool get isProduction =>
      kReleaseMode || _environment.toLowerCase() == 'production';

  static String get baseUrl {
    if (_urlOverride.isNotEmpty) return _urlOverride;
    if (isProduction) return productionUrl;
    if (kIsWeb) return 'http://localhost:4000';
    if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }
}
