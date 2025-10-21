import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:async';

class Todolist extends StatefulWidget {
  final String TaskName;
  final bool IsChecked;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? Delete_Fun;
  final Function(BuildContext)? Update_Fun;
  
  // Timer properties
  final bool hasTimer;
  final int? totalDuration; // in seconds
  final int elapsedSeconds;
  final bool isRunning;
  final VoidCallback? onTimerToggle;
  final VoidCallback? onTimerReset;
  
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
    this.onTimerToggle,
    this.onTimerReset,
    this.isSynced = true, // Default to synced
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
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(Todolist oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle timer state changes
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
    
    // Update elapsed time if changed externally
    if (widget.elapsedSeconds != oldWidget.elapsedSeconds) {
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Check if timer has completed
      if (widget.totalDuration != null && _currentElapsed >= widget.totalDuration!) {
        _stopTimer();
        widget.onTimerToggle?.call();
        // Show completion notification
        _showTimerCompleteSnackbar();
        return;
      }
      
      setState(() {
        _currentElapsed++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _showTimerCompleteSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.alarm, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Timer completed for "${widget.TaskName}"!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
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
    return (_currentElapsed / widget.totalDuration!).clamp(0.0, 1.0);
  }

  Color _getTimerColor() {
    final progress = _getProgress();
    if (progress < 0.5) {
      return Color(0xFF4CAF50); // Green
    } else if (progress < 0.8) {
      return Color(0xFFFFA726); // Orange
    } else {
      return Color(0xFFEF5350); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: widget.Update_Fun,
              icon: Icons.edit_rounded,
              backgroundColor: Color(0xFF448AFF),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: widget.Delete_Fun,
              icon: Icons.delete_rounded,
              backgroundColor: Color(0xFFEF5350),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.IsChecked
                  ? [
                      Color(0xFFE8EAF6),
                      Color(0xFFC5CAE9),
                    ]
                  : [
                      Colors.white,
                      Color(0xFFFAFAFA),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.IsChecked
                  ? Color(0xFF7C4DFF).withOpacity(0.3)
                  : widget.isSynced
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.4), // Orange border if not synced
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.IsChecked
                    ? Color(0xFF7C4DFF).withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onChanged?.call(!widget.IsChecked),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Main Task Row
                    Row(
                      children: [
                        // Custom Checkbox
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: widget.IsChecked
                                ? LinearGradient(
                                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: widget.IsChecked ? null : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.IsChecked
                                  ? Colors.transparent
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            boxShadow: widget.IsChecked
                                ? [
                                    BoxShadow(
                                      color: Color(0xFF7C4DFF).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: widget.IsChecked
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        
                        // Task Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.TaskName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.IsChecked
                                      ? Colors.grey.shade600
                                      : Color(0xFF2C3E50),
                                  decoration: widget.IsChecked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: Colors.grey.shade400,
                                  decorationThickness: 2,
                                ),
                              ),
                              if (widget.IsChecked) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Sync Status Indicator
                        if (!widget.isSynced) ...[
                          Tooltip(
                            message: 'Syncing to cloud...',
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Syncing',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        
                        // Timer Badge
                        if (widget.hasTimer) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF7C4DFF).withOpacity(0.15),
                                  Color(0xFF448AFF).withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF7C4DFF).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Color(0xFF7C4DFF),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Timer',
                                  style: TextStyle(
                                    color: Color(0xFF7C4DFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        
                        // Swipe Indicator
                        Icon(
                          Icons.chevron_left,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                    
                    // Timer Section
                    if (widget.hasTimer && widget.totalDuration != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getTimerColor().withOpacity(0.1),
                              _getTimerColor().withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getTimerColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Progress Bar
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: _getProgress(),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getTimerColor(),
                                          _getTimerColor().withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getTimerColor().withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            
                            // Timer Controls Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Time Display
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _getTimerColor().withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        widget.isRunning 
                                            ? Icons.play_circle_filled 
                                            : Icons.access_time,
                                        size: 18,
                                        color: _getTimerColor(),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatTime(_currentElapsed),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getTimerColor(),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'of ${_formatTime(widget.totalDuration!)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // Control Buttons
                                Row(
                                  children: [
                                    // Play/Pause Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: widget.onTimerToggle,
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: widget.isRunning
                                                  ? [Color(0xFFFFA726), Color(0xFFFF9800)]
                                                  : [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (widget.isRunning 
                                                    ? Color(0xFFFFA726) 
                                                    : Color(0xFF4CAF50))
                                                    .withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            widget.isRunning 
                                                ? Icons.pause_rounded 
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    
                                    // Reset Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // Show confirmation dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              title: Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Color(0xFFFFA726),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Reset Timer?'),
                                                ],
                                              ),
                                              content: Text(
                                                'Are you sure you want to reset the timer? This will set the elapsed time back to zero.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(color: Colors.grey),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    widget.onTimerReset?.call();
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFFEF5350),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Reset',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFFEF5350).withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.refresh_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Timer Status Text
                            if (widget.isRunning) ...[
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF4CAF50).withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Timer Running',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
