import 'package:flutter/material.dart';

class CustomToast {
  static final GlobalKey<_ToastOverlayState> _overlayKey = GlobalKey();
  static OverlayEntry? _overlayEntry;

  // Initialize overlay (call this once in your main.dart MaterialApp builder)
  static void initialize(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _ToastOverlay(key: _overlayKey),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  // Simple success toast
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
    );
  }

  // Simple error toast
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      gradient: [const Color(0xFFEF5350), const Color(0xFFE57373)],
    );
  }

  // Simple warning toast
  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      gradient: [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
    );
  }

  // Simple info toast
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      gradient: [const Color(0xFF42A5F5), const Color(0xFF64B5F6)],
    );
  }

  // Detailed versions with duration control
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      gradient: [const Color(0xFFEF5350), const Color(0xFFE57373)],
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      gradient: [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      gradient: [const Color(0xFF42A5F5), const Color(0xFF64B5F6)],
      duration: duration,
    );
  }

  static void showCustom(
    BuildContext context,
    String message, {
    required IconData icon,
    required List<Color> gradientColors,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      gradient: gradientColors,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required List<Color> gradient,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_overlayKey.currentState == null) {
      initialize(context);
    }
    
    _overlayKey.currentState?.addToast(
      message: message,
      icon: icon,
      gradient: gradient,
      duration: duration,
    );
  }

  static void cancel() {
    _overlayKey.currentState?.clearAll();
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({super.key});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  final List<_ToastData> _toasts = [];
  static const int maxToasts = 5;

  void addToast({
    required String message,
    required IconData icon,
    required List<Color> gradient,
    required Duration duration,
  }) {
    setState(() {
      if (_toasts.length >= maxToasts) {
        _toasts.removeAt(0);
      }
      _toasts.add(_ToastData(
        message: message,
        icon: icon,
        gradient: gradient,
        duration: duration,
      ));
    });

    Future.delayed(duration, () {
      if (mounted && _toasts.isNotEmpty) {
        setState(() {
          _toasts.removeWhere((t) => 
            t.message == message && 
            t.icon == icon
          );
        });
      }
    });
  }

  void clearAll() {
    if (mounted) {
      setState(() {
        _toasts.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 100,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: _toasts.isEmpty,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _toasts.asMap().entries.map((entry) {
            final index = entry.key;
            final toast = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: index == _toasts.length - 1 ? 0 : 4,
              ),
              child: _ToastItem(
                message: toast.message,
                icon: toast.icon,
                gradient: toast.gradient,
                index: _toasts.length - 1 - index,
                onDismiss: () {
                  setState(() {
                    _toasts.removeAt(index);
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ToastData {
  final String message;
  final IconData icon;
  final List<Color> gradient;
  final Duration duration;

  _ToastData({
    required this.message,
    required this.icon,
    required this.gradient,
    required this.duration,
  });
}

class _ToastItem extends StatefulWidget {
  final String message;
  final IconData icon;
  final List<Color> gradient;
  final int index;
  final VoidCallback onDismiss;

  const _ToastItem({
    required this.message,
    required this.icon,
    required this.gradient,
    required this.index,
    required this.onDismiss,
  });

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss(),
            child: Transform.scale(
              scale: 1.0 - (widget.index * 0.02),
              child: Opacity(
                opacity: 1.0 - (widget.index * 0.1),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient[0].withValues(alpha: 0.4),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
