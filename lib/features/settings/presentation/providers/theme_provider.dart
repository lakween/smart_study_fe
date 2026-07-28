import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier(super.initialValue);

  Future<void> setDarkMode(bool enabled) async {
    state = enabled;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AppConstants.darkModeKey, enabled);
  }
}

final darkModeProvider =
    StateNotifierProvider<DarkModeNotifier, bool>((ref) => DarkModeNotifier(false));

