import 'package:flutter/material.dart';
import 'package:reusehub/core/constants/app_theme.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? AppColors.charcoal,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
          ),
        ),
      );
  }

  static void error(BuildContext context, String message) {
    show(context, message, backgroundColor: AppColors.error);
  }

  static void success(BuildContext context, String message) {
    show(context, message, backgroundColor: AppColors.success);
  }
}
