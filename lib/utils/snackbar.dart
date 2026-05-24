import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/utils/app_ui.dart';

class AppSnackBar {
  /// Displays a standardized success SnackBar.
  static void success(BuildContext? context, String message) {
    _show(context, message, AppColors.onlineGreen, Icons.check_circle_outline);
  }

  /// Displays a standardized error SnackBar.
  static void error(BuildContext? context, String message) {
    _show(context, message, AppColors.errorRed, Icons.error_outline);
  }

  /// Displays a standardized info SnackBar.
  static void info(BuildContext? context, String message) {
    _show(context, message, AppColors.primaryPurple, Icons.info_outline);
  }

  /// Displays a standardized warning SnackBar.
  static void warning(BuildContext? context, String message) {
    _show(
      context,
      message,
      AppColors.warningOrange,
      Icons.warning_amber_rounded,
    );
  }

  static void _show(
    BuildContext? context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger =
        scaffoldMessengerKey.currentState ??
        (context == null ? null : ScaffoldMessenger.maybeOf(context));
    if (messenger == null) return;

    // Dismiss existing snackbars to avoid stacking lag
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Legacy support for existing showCustomSnackBar calls.
/// New code should use AppSnackBar.success/error/info.
void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (isError) {
    AppSnackBar.error(context, message);
  } else {
    AppSnackBar.success(context, message);
  }
}
