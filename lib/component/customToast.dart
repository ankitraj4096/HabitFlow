import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static final FToast _fToast = FToast();

  static void init(BuildContext context) {
    _fToast.init(context);
  }

  // Success toast
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _fToast.init(context);
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.check_circle,
        gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  // Error toast
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _fToast.init(context);
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.error,
        gradient: [const Color(0xFFEF5350), const Color(0xFFE57373)],
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  // Warning toast
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _fToast.init(context);
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.warning_amber_rounded,
        gradient: [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  // Info toast
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _fToast.init(context);
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.info,
        gradient: [const Color(0xFF42A5F5), const Color(0xFF64B5F6)],
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  // Custom toast with tier colors
  static void showCustom(
    BuildContext context,
    String message, {
    required IconData icon,
    required List<Color> gradientColors,
    Duration duration = const Duration(seconds: 3),
  }) {
    _fToast.init(context);
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: icon,
        gradient: gradientColors,
      ),
      gravity: ToastGravity.BOTTOM,
      toastDuration: duration,
    );
  }

  // Build toast container
  static Widget _buildToastContainer({
    required String message,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Cancel all toasts
  static void cancel() {
    _fToast.removeCustomToast();
  }
}
