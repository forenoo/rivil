import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final SnackBar snackBar = SnackBar(
      content: _CustomSnackbarContent(
        message: message,
        type: type,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
    );
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

enum SnackbarType { success, info, warning, error }

class _CustomSnackbarContent extends StatelessWidget {
  final String message;
  final SnackbarType type;

  const _CustomSnackbarContent({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          _getIcon(),
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case SnackbarType.success:
        return Icons.check;
      case SnackbarType.info:
        return Icons.info;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.error:
        return Icons.error;
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case SnackbarType.success:
        return const Color(0xFFEDF7ED);
      case SnackbarType.info:
        return const Color(0xFFE8F4FD);
      case SnackbarType.warning:
        return const Color(0xFFFFF8E6);
      case SnackbarType.error:
        return const Color(0xFFFDECEF);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case SnackbarType.success:
        return const Color(0xFF1E4620);
      case SnackbarType.info:
        return const Color(0xFF0A558C);
      case SnackbarType.warning:
        return const Color(0xFF663C00);
      case SnackbarType.error:
        return const Color(0xFF621B21);
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case SnackbarType.success:
        return const Color(0xFF4CAF50);
      case SnackbarType.info:
        return const Color(0xFF2196F3);
      case SnackbarType.warning:
        return const Color(0xFFFFC107);
      case SnackbarType.error:
        return const Color(0xFFF44336);
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case SnackbarType.success:
        return const Color(0xFFAED581);
      case SnackbarType.info:
        return const Color(0xFF90CAF9);
      case SnackbarType.warning:
        return const Color(0xFFFFD54F);
      case SnackbarType.error:
        return const Color(0xFFE57373);
    }
  }
}
