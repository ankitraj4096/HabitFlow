import 'package:demo/component/custom_toast.dart';
import 'package:demo/component/water_droplet.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Todolist extends StatefulWidget {
  final String taskName;
  final bool isChecked;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFun;
  final Function(BuildContext)? updateFun;

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

  // ✅ NEW: Recurring status
  final bool isRecurring;

  const Todolist({
    super.key,
    required this.taskName,
    required this.isChecked,
    required this.onChanged,
    required this.deleteFun,
    required this.updateFun,
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
    this.isRecurring = false,  // ✅ NEW
  });

  @override
  State<Todolist> createState() => _TodolistState();
}

class _TodolistState extends State<Todolist> {
  Timer? timer;
  int currentElapsed = 0;

  @override
  void initState() {
    super.initState();
    currentElapsed = widget.elapsedSeconds;
    if (widget.isRunning) {
      startLocalTimer();
    }
  }

  @override
  void didUpdateWidget(Todolist oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        startLocalTimer();
      } else {
        stopLocalTimer();
      }
    }

    if (widget.elapsedSeconds != oldWidget.elapsedSeconds) {
      setState(() {
        currentElapsed = widget.elapsedSeconds;
      });
    }

    if (widget.resetKey != oldWidget.resetKey) {
      setState(() {
        currentElapsed = widget.elapsedSeconds;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startLocalTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.totalDuration != null &&
          currentElapsed >= widget.totalDuration!) {
        stopLocalTimer();
        widget.onTimerPause?.call();
        showTimerCompleteToast();
        if (widget.onTimerComplete != null && !widget.isChecked) {
          widget.onTimerComplete!();
        }
        return;
      }
      setState(() {
        currentElapsed++;
      });
    });
  }

  void stopLocalTimer() {
    timer?.cancel();
  }

  void showTimerCompleteToast() {
    if (!mounted) return;
    final tierProvider = context.read<TierThemeProvider>();
    CustomToast.showCustom(
      context,
      'Timer completed for ${widget.taskName}!',
      icon: Icons.alarm,
      gradientColors: tierProvider.gradientColors,
      duration: const Duration(seconds: 3),
    );
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double getProgress() {
    if (widget.totalDuration == null || widget.totalDuration == 0) {
      return 0.0;
    }
    if (widget.isChecked) {
      return 1.0;
    }
    return (currentElapsed / widget.totalDuration!).clamp(0.0, 1.0);
  }

  Color getWaterColor() {
    final progress = getProgress();
    if (progress < 0.33) {
      return const Color(0xFF4FC3F7);
    } else if (progress < 0.66) {
      return const Color(0xFF29B6F6);
    } else {
      return const Color(0xFF0288D1);
    }
  }

  void showResetDialog() {
    final tierProvider = context.read<TierThemeProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E5F5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: tierProvider.glowColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tierProvider.glowColor.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Timer?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tierProvider.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All progress will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tierProvider.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: tierProvider.glowColor.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          widget.onTimerStop?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          motion: const DrawerMotion(),
          extentRatio: 0.45,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 2),
                child: GestureDetector(
                  onTap: () => widget.updateFun?.call(context),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: tierProvider.glowColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 4),
                child: GestureDetector(
                  onTap: () => widget.deleteFun?.call(context),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF5350).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isChecked
                  ? tierProvider.primaryColor.withValues(alpha: 0.3)
                  : widget.isSynced
                      ? Colors.grey.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isChecked
                    ? tierProvider.glowColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
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
                if (widget.hasTimer && widget.totalDuration != null)
                  Positioned.fill(
                    child: WaterDropletEffect(
                      progress: getProgress(),
                      isRunning: widget.isRunning,
                      waterColor: getWaterColor(),
                      resetKey: widget.resetKey,
                    ),
                  ),
                if (!widget.hasTimer || widget.totalDuration == null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isChecked
                              ? [
                                  tierProvider.primaryColor
                                      .withValues(alpha: 0.15),
                                  tierProvider.glowColor.withValues(alpha: 0.1),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFFAFAFA),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (widget.isRunning) {
                        CustomToast.warning(
                          context,
                          'Cannot mark as complete while timer is running',
                        );
                        return;
                      }
                      widget.onChanged?.call(!widget.isChecked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: widget.isChecked
                                      ? LinearGradient(
                                          colors: tierProvider.gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: widget.isChecked
                                        ? Colors.transparent
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.isChecked
                                          ? tierProvider.glowColor
                                              .withValues(alpha: 0.3)
                                          : Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: widget.isChecked
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Wrap(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.95),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            widget.taskName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: widget.isChecked
                                                  ? Colors.grey.shade600
                                                  : const Color(0xFF2C3E50),
                                              decoration: widget.isChecked
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
                                              color: Colors.white
                                                  .withValues(alpha: 0.95),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
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
                                                  'From ${widget.assignedByUsername}',
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
                                    if (widget.isChecked) ...[
                                      const SizedBox(height: 3),
                                      Wrap(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.95),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
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
                                        color: Colors.orange
                                            .withValues(alpha: 0.96),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
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
                                  // ✅ NEW: Recurring badge
                                  if (widget.isRecurring)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9C27B0)
                                            .withValues(alpha: 0.96),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.repeat_rounded,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Daily',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.isRecurring)
                                    const SizedBox(height: 3),
                                  if (widget.hasTimer)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tierProvider.primaryColor
                                            .withValues(alpha: 0.96),
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
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
                          if (widget.hasTimer && widget.totalDuration != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.08),
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
                                        color: getWaterColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isChecked
                                            ? formatTime(widget.totalDuration!)
                                            : formatTime(currentElapsed),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: getWaterColor(),
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        ' / ${formatTime(widget.totalDuration!)}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buildMicroButton(
                                      icon: widget.isRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: widget.isRunning
                                          ? const Color(0xFFFFA726)
                                          : const Color(0xFF4CAF50),
                                      onTap: () {
                                        if (widget.isChecked) {
                                          CustomToast.warning(
                                            context,
                                            'Timer controls disabled for completed tasks',
                                          );
                                          return;
                                        }
                                        if (widget.isRunning) {
                                          widget.onTimerPause?.call();
                                        } else {
                                          widget.onTimerStart?.call();
                                        }
                                      },
                                      isDisabled: widget.isChecked,
                                    ),
                                    const SizedBox(width: 5),
                                    buildMicroButton(
                                      icon: Icons.refresh_rounded,
                                      color: const Color(0xFFEF5350),
                                      onTap: () {
                                        if (widget.isChecked) {
                                          CustomToast.warning(
                                            context,
                                            'Timer controls disabled for completed tasks',
                                          );
                                          return;
                                        }
                                        showResetDialog();
                                      },
                                      isDisabled: widget.isChecked,
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

  Widget buildMicroButton({
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
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
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
