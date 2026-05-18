import 'package:flutter/material.dart';
import '../core/theme.dart';

enum AppToastType { info, success, error, warning }

class AppToast {
  static void show({
    required BuildContext context,
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  static Color _getColor(AppToastType type) {
    switch (type) {
      case AppToastType.info:
        return AppColors.secondary;
      case AppToastType.success:
        return Colors.green;
      case AppToastType.error:
        return Colors.red;
      case AppToastType.warning:
        return Colors.orange;
    }
  }

  static IconData _getIcon(AppToastType type) {
    switch (type) {
      case AppToastType.info:
        return Icons.info_outline;
      case AppToastType.success:
        return Icons.check_circle_outline;
      case AppToastType.error:
        return Icons.error_outline;
      case AppToastType.warning:
        return Icons.warning_amber_outlined;
    }
  }

  static void showSuccess(BuildContext context, String message) {
    show(context: context, message: message, type: AppToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context: context, message: message, type: AppToastType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context: context, message: message, type: AppToastType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context: context, message: message, type: AppToastType.info);
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.secondary),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!, style: const TextStyle(fontSize: 16)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.secondary),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!, style: const TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}