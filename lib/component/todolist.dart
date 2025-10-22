import 'package:demo/component/customToast.dart';
import 'package:demo/component/water_droplet.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Todolist extends StatefulWidget {
  final String TaskName;
  final bool IsChecked;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? Delete_Fun;
  final Function(BuildContext)? Update_Fun;

  // Timer properties
  final bool hasTimer;
  final int? totalDuration;
  final int elapsedSeconds;
  final bool isRunning;
  final VoidCallback? onTimerComplete;
  final String? assignedByUsername;

  // Separate timer controls
  final VoidCallback? onTimerStart;
  final VoidCallback? onTimerPause;
  final VoidCallback? onTimerStop;
  final int resetKey;

  // Sync status
  final bool isSynced;

  const Todolist({
    super.key,
    required this.TaskName,
    required this.IsChecked,
    required this.onChanged,
    required this.Delete_Fun,
    required this.Update_Fun,
    this.hasTimer = false,
    this.totalDuration,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.onTimerStart,
    this.onTimerPause,
    this.onTimerStop,
    this.isSynced = true,
    required this.assignedByUsername,
    required this.onTimerComplete,
    this.resetKey = 0,
  });

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  Timer? _timer;
  int _currentElapsed = 0;

  @override
  void initState() {
    super.initState();
    _currentElapsed = widget.elapsedSeconds;
    if (widget.isRunning) {
      _startLocalTimer();
    }
  }

  @override
  void didUpdateWidget(Todolist oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startLocalTimer();
      } else {
        _stopLocalTimer();
      }
    }

    // ✅ Update local elapsed time immediately when prop changes
    if (widget.elapsedSeconds != oldWidget.elapsedSeconds) {
      setState(() {
        _currentElapsed = widget.elapsedSeconds;
      });
    }

    // ✅ Handle reset key change for instant drain
    if (widget.resetKey != oldWidget.resetKey) {
      setState(() {
        _currentElapsed = widget.elapsedSeconds;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.totalDuration != null &&
          _currentElapsed >= widget.totalDuration!) {
        _stopLocalTimer();
        widget.onTimerPause?.call();
        _showTimerCompleteToast();
        if (widget.onTimerComplete != null && !widget.IsChecked) {
          widget.onTimerComplete!();
        }
        return;
      }

      setState(() {
        _currentElapsed++;
      });
    });
  }

  void _stopLocalTimer() {
    _timer?.cancel();
  }

  void _showTimerCompleteToast() {
    if (mounted) {
      CustomToast.showSuccess(
        context,
        'Timer completed for "${widget.TaskName}"!',
      );
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (widget.totalDuration == null || widget.totalDuration == 0) {
      return 0.0;
    }

    // If task is completed, show full progress
    if (widget.IsChecked) {
      return 1.0;
    }

    return (_currentElapsed / widget.totalDuration!).clamp(0.0, 1.0);
  }

  Color _getWaterColor() {
    final progress = _getProgress();
    if (progress < 0.33) {
      return const Color(0xFF4FC3F7);
    } else if (progress < 0.66) {
      return const Color(0xFF29B6F6);
    } else {
      return const Color(0xFF0288D1);
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726)),
            SizedBox(width: 8),
            Text('Reset Timer?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to reset the timer? Water will drain and restart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onTimerStop?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: widget.Update_Fun,
              icon: Icons.edit_rounded,
              backgroundColor: tierProvider.primaryColor,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: widget.Delete_Fun,
              icon: Icons.delete_rounded,
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.IsChecked
                  ? tierProvider.primaryColor.withOpacity(0.3)
                  : widget.isSynced
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.IsChecked
                    ? tierProvider.glowColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ✅ Water droplet background
                if (widget.hasTimer && widget.totalDuration != null)
                  Positioned.fill(
                    child: WaterDropletEffect(
                      progress: _getProgress(),
                      isRunning: widget.isRunning,
                      waterColor: _getWaterColor(),
                      resetKey: widget.resetKey,
                    ),
                  ),

                // ✅ Gradient overlay for non-timer tasks
                if (!widget.hasTimer || widget.totalDuration == null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.IsChecked
                              ? [
                                  tierProvider.primaryColor.withOpacity(0.15),
                                  tierProvider.glowColor.withOpacity(0.1),
                                ]
                              : [Colors.white, const Color(0xFFFAFAFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),

                // ✅ Content overlay
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Prevent marking complete if timer is running
                      if (widget.isRunning) {
                        CustomToast.showWarning(
                          context,
                          'Cannot mark as complete while timer is running',
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }
                      widget.onChanged?.call(!widget.IsChecked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Main Task Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checkbox
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: widget.IsChecked
                                      ? LinearGradient(
                                          colors: tierProvider.gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: widget.IsChecked
                                        ? Colors.transparent
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.IsChecked
                                          ? tierProvider.glowColor.withOpacity(
                                              0.3,
                                            )
                                          : Colors.black.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: widget.IsChecked
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),

                              // ✅ Task text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Task name
                                    Wrap(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            widget.TaskName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: widget.IsChecked
                                                  ? Colors.grey.shade600
                                                  : const Color(0xFF2C3E50),
                                              decoration: widget.IsChecked
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              decorationColor:
                                                  Colors.grey.shade400,
                                              decorationThickness: 2,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Assigned by
                                    if (widget.assignedByUsername != null) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.95,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 11,
                                                  color:
                                                      tierProvider.primaryColor,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'From: ${widget.assignedByUsername}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: tierProvider
                                                        .primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Completed badge
                                    if (widget.IsChecked) ...[
                                      const SizedBox(height: 3),
                                      Wrap(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.95,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 10,
                                                  color:
                                                      tierProvider.primaryColor,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Completed',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: tierProvider
                                                        .primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Badges column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!widget.isSynced)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.96),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Sync',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!widget.isSynced)
                                    const SizedBox(height: 3),
                                  if (widget.hasTimer)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tierProvider.primaryColor
                                            .withOpacity(0.96),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Timer',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          // ✅ Timer controls row
                          if (widget.hasTimer &&
                              widget.totalDuration != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Time display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        size: 12,
                                        color: _getWaterColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        // Show full time if completed
                                        widget.IsChecked
                                            ? _formatTime(widget.totalDuration!)
                                            : _formatTime(_currentElapsed),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _getWaterColor(),
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        ' / ${_formatTime(widget.totalDuration!)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Control buttons - disabled if completed
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMicroButton(
                                      icon: widget.isRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: widget.isRunning
                                          ? const Color(0xFFFFA726)
                                          : const Color(0xFF4CAF50),
                                      onTap: widget.IsChecked
                                          ? () {
                                              CustomToast.showWarning(
                                                context,
                                                'Timer controls disabled for completed tasks',
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              );
                                            }
                                          : () {
                                              if (widget.isRunning) {
                                                widget.onTimerPause?.call();
                                              } else {
                                                widget.onTimerStart?.call();
                                              }
                                            },
                                      isDisabled: widget.IsChecked,
                                    ),
                                    const SizedBox(width: 5),
                                    _buildMicroButton(
                                      icon: Icons.refresh_rounded,
                                      color: const Color(0xFFEF5350),
                                      onTap: widget.IsChecked
                                          ? () {
                                              CustomToast.showWarning(
                                                context,
                                                'Timer controls disabled for completed tasks',
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              );
                                            }
                                          : _showResetDialog,
                                      isDisabled: widget.IsChecked,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade400 : color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}
