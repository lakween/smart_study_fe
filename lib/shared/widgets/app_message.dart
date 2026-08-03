import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

abstract final class AppMessage {
  static void error(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: SelectableText(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }
}
