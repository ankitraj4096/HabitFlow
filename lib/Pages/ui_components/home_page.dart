import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/Pages/ui_components/friend_components/taskRequestsPage.dart';
import 'package:demo/component/customToast.dart';
import 'package:demo/component/todolist.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:demo/services/notification_service.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> tasklist = [];
  final TextEditingController control = TextEditingController();
  final TextEditingController timerController = TextEditingController();
  final FireStoreService firestoreService = FireStoreService();
  final NotificationService _notificationService = NotificationService();
  bool _isSyncing = false;
  StreamSubscription<QuerySnapshot>? _firebaseSubscription;
  Timer? _uiUpdateTimer;
  Timer? _notificationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
    _initializeData();
    _startUIUpdateTimer();
    _startNotificationUpdateTimer();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    _notificationUpdateTimer?.cancel();
    control.dispose();
    timerController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotificationService() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  void _startUIUpdateTimer() {
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      for (int i = 0; i < tasklist.length; i++) {
        if (tasklist[i]['isRunning'] == true) {
          final currentElapsed = tasklist[i]['elapsedSeconds'] ?? 0;
          setState(() {
            tasklist[i]['elapsedSeconds'] = currentElapsed + 1;
          });
        }
      }
    });
  }

  // Replace the _startNotificationUpdateTimer method with this:
  void _startNotificationUpdateTimer() {
    _notificationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      _updateTimerNotification();
    });
  }

  // Replace the _updateTimerNotification method with this improved version:
  Future<void> _updateTimerNotification() async {
    // Find any running timer
    final runningTask = tasklist.firstWhere(
      (task) => task['isRunning'] == true,
      orElse: () => {},
    );

    if (runningTask.isEmpty) {
      // No running timer, cancel notification
      await _notificationService.cancelTimerNotification();
      return;
    }

    final taskName = runningTask['taskName'] ?? 'Task';
    final elapsedSeconds = runningTask['elapsedSeconds'] ?? 0;
    final totalDuration = runningTask['totalDuration'];

    String timerText;
    String subText;
    int? progress;
    int? maxProgress;
    double? percentComplete;

    if (totalDuration != null) {
      // Timer with duration - show countdown
      final remainingSeconds = totalDuration - elapsedSeconds;

      timerText = _formatTimeEnhanced(remainingSeconds);
      subText = '${_formatTimeEnhanced(elapsedSeconds)} elapsed';
      progress = elapsedSeconds;
      maxProgress = totalDuration;
      percentComplete = (elapsedSeconds / totalDuration * 100).clamp(0, 100);
    } else {
      // Timer without duration - show elapsed time
      timerText = _formatTimeEnhanced(elapsedSeconds);
      subText = 'Stopwatch mode';
      progress = null;
      maxProgress = null;
      percentComplete = null;
    }

    await _notificationService.updateTimerNotification(
      taskName: taskName,
      timerText: timerText,
      subText: subText,
      progress: progress,
      maxProgress: maxProgress,
      percentComplete: percentComplete,
    );
  }

  String _formatTimeEnhanced(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isSyncing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        listenToFirebaseChanges();
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void listenToFirebaseChanges() {
    _firebaseSubscription?.cancel();
    _firebaseSubscription = firestoreService.getTasksStream().listen(
      (snapshot) {
        List<Map<String, dynamic>> updatedTasks = [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];
          if (status == 'pending') continue;

          final isCompleted = data['isCompleted'] ?? false;
          if (isCompleted) {
            final completedAt = data['completedAt'] as Timestamp?;
            if (completedAt != null) {
              final completedDate = completedAt.toDate();
              if (completedDate.isBefore(todayStart) ||
                  completedDate.isAfter(todayEnd)) {
                continue;
              }
            } else {
              continue;
            }
          }

          int currentElapsedSeconds = data['elapsedSeconds'] ?? 0;
          final isRunning = data['isRunning'] ?? false;

          if (isRunning && data['startTime'] != null) {
            final startTime = (data['startTime'] as Timestamp).toDate();
            final runningDuration = DateTime.now()
                .difference(startTime)
                .inSeconds;
            currentElapsedSeconds =
                (data['elapsedSeconds'] ?? 0) + runningDuration;
          }

          updatedTasks.add({
            'firebaseId': doc.id,
            'isCompleted': isCompleted,
            'taskName': data['taskName'] ?? '',
            'hasTimer': data['hasTimer'] ?? false,
            'totalDuration': data['totalDuration'],
            'elapsedSeconds': currentElapsedSeconds,
            'isRunning': isRunning,
            'lastUpdated': data['lastUpdated'],
            'completedAt': data['completedAt'],
            'assignedByUserID': data['assignedByUserID'],
            'assignedByUsername': data['assignedByUsername'],
            'status': status ?? 'accepted',
          });
        }

        setState(() {
          tasklist = updatedTasks;
        });

        _updateTimerNotification();
      },
      onError: (error) {
        print('Error listening to Firebase: $error');
      },
    );
  }

  void _autoCompleteTask(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null || task['isCompleted'] == true) {
      return;
    }

    setState(() {
      tasklist[index]['isCompleted'] = true;
      tasklist[index]['completedAt'] = Timestamp.now();
    });

    try {
      await firestoreService.toggleCompletion(firebaseId, false);
    } catch (e) {
      print('Error auto-completing task: $e');
      setState(() {
        tasklist[index]['isCompleted'] = false;
        tasklist[index]['completedAt'] = null;
      });
      if (mounted) {
        CustomToast.error(context, 'Failed to auto-complete task');
      }
    }
  }

  void Add_Task() async {
    if (control.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final taskName = control.text;
    final timerMinutes = timerController.text.isNotEmpty
        ? int.tryParse(timerController.text)
        : null;

    Navigator.of(context).pop();
    control.clear();
    timerController.clear();

    setState(() => _isSyncing = true);

    try {
      final firebaseId = await firestoreService.addTask(
        false,
        taskName,
        timerMinutes,
      );

      if (firebaseId == null) {
        throw Exception('Failed to add task to Firebase');
      }
    } catch (e) {
      print('Error adding to Firebase: $e');
      if (mounted) {
        CustomToast.showError(context, 'Failed to add task. Please try again.');
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void NewTask() {
    final tierProvider = context.read<TierThemeProvider>();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: tierProvider.glowColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: tierProvider.glowColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Task',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: tierProvider.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Create your task below',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Task Name TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: TextField(
                  controller: control,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Enter your task...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      color: tierProvider.primaryColor,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Timer TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: TextField(
                  controller: timerController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Timer (minutes)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Optional, e.g., 25',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.timer_outlined,
                      color: tierProvider.primaryColor,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  // Cancel button
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          control.clear();
                          timerController.clear();
                        },
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

                  // Save button with gradient
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
                            color: tierProvider.glowColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: Add_Task,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Save',
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

  void CheckBoxChanged(bool? value, int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null) {
      CustomToast.showWarning(
        context,
        'Please wait for task to sync...',
        duration: const Duration(seconds: 1),
      );
      return;
    }

    final newCompletedStatus = !tasklist[index]['isCompleted'];

    setState(() {
      tasklist[index]['isCompleted'] = newCompletedStatus;
      if (newCompletedStatus) {
        tasklist[index]['completedAt'] = Timestamp.now();
        if (task['hasTimer'] == true && task['totalDuration'] != null) {
          tasklist[index]['elapsedSeconds'] = task['totalDuration'];
          tasklist[index]['isRunning'] = false;
        }
      } else {
        tasklist[index]['completedAt'] = null;
        if (task['hasTimer'] == true) {
          tasklist[index]['elapsedSeconds'] = 0;
          tasklist[index]['isRunning'] = false;
          tasklist[index]['resetKey'] = (task['resetKey'] ?? 0) + 1;
        }
      }
    });

    try {
      await firestoreService.toggleCompletion(firebaseId, !newCompletedStatus);
      if (!newCompletedStatus && task['hasTimer'] == true) {
        await FirebaseFirestore.instance
            .collection('user_notes')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notes')
            .doc(firebaseId)
            .update({'elapsedSeconds': 0, 'isRunning': false});
      }

      await _updateTimerNotification();
    } catch (e) {
      print('Error updating Firebase: $e');
      setState(() {
        tasklist[index]['isCompleted'] = !newCompletedStatus;
        if (!newCompletedStatus) {
          tasklist[index]['completedAt'] = null;
        }
      });
      if (mounted) {
        CustomToast.showError(
          context,
          'Failed to update task. Please try again.',
        );
      }
    }
  }

  void DeleteTask(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null) {
      CustomToast.showWarning(
        context,
        'Cannot delete task that is not synced',
        duration: const Duration(seconds: 1),
      );
      return;
    }

    final deletedTask = tasklist[index];
    setState(() {
      tasklist.removeAt(index);
    });

    try {
      await firestoreService.deleteTask(firebaseId);
      await _updateTimerNotification();
    } catch (e) {
      print('Error deleting from Firebase: $e');
      setState(() {
        tasklist.insert(index, deletedTask);
      });
      if (mounted) {
        CustomToast.showError(
          context,
          'Failed to delete task. Please try again.',
        );
      }
    }
  }

  void UpdateTask(int index) {
    final tierProvider = context.read<TierThemeProvider>();
    final task = tasklist[index];
    control.text = task['taskName'];
    if (task['hasTimer'] == true && task['totalDuration'] != null) {
      timerController.text = (task['totalDuration'] / 60).round().toString();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: tierProvider.glowColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: tierProvider.glowColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Task',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: tierProvider.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Edit your task details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Task Name TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: TextField(
                  controller: control,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Enter task name...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.edit_rounded,
                      color: tierProvider.primaryColor,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Timer TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: TextField(
                  controller: timerController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Timer (minutes)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    hintText: 'Leave empty to remove',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.timer_outlined,
                      color: tierProvider.primaryColor,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  // Cancel button
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          control.clear();
                          timerController.clear();
                        },
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

                  // Update button with gradient
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
                            color: tierProvider.glowColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final firebaseId = tasklist[index]['firebaseId'];
                          if (firebaseId == null) {
                            CustomToast.showWarning(
                              context,
                              'Please wait for task to sync...',
                            );
                            return;
                          }

                          final timerMinutes = timerController.text.isNotEmpty
                              ? int.tryParse(timerController.text)
                              : null;
                          final updatedTaskName = control.text;

                          Navigator.of(context).pop();
                          control.clear();
                          timerController.clear();

                          try {
                            await firestoreService.updateTask(
                              firebaseId,
                              tasklist[index]['isCompleted'],
                              updatedTaskName,
                              timerMinutes,
                            );
                          } catch (e) {
                            print('Error updating Firebase: $e');
                            if (mounted) {
                              CustomToast.showError(
                                context,
                                'Failed to update task.',
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Update',
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

  int get completedTasksCount {
    return tasklist.where((task) => task['isCompleted'] == true).length;
  }

  void _startTimer(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null) return;

    setState(() {
      tasklist[index]['isRunning'] = true;
    });

    try {
      await firestoreService.startTimer(firebaseId);
      await _updateTimerNotification();
    } catch (e) {
      print('Error starting timer: $e');
      setState(() {
        tasklist[index]['isRunning'] = false;
      });
    }
  }

  void _pauseTimer(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null) return;

    final currentElapsed = task['elapsedSeconds'] ?? 0;

    setState(() {
      tasklist[index]['isRunning'] = false;
    });

    try {
      await firestoreService.pauseTimer(firebaseId, currentElapsed);
      await _notificationService.cancelTimerNotification();
    } catch (e) {
      print('Error pausing timer: $e');
      setState(() {
        tasklist[index]['isRunning'] = true;
      });
    }
  }

  void _stopTimer(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    if (firebaseId == null) return;

    setState(() {
      tasklist[index]['isRunning'] = false;
      tasklist[index]['elapsedSeconds'] = 0;
    });

    try {
      await firestoreService.stopTimer(firebaseId);
      await _notificationService.cancelTimerNotification();
    } catch (e) {
      print('Error stopping timer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E5F5), Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierProvider.glowColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Task List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Stay organized and productive 📝',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_isSyncing) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white70,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TaskRequestsPage(),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.inbox,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              StreamBuilder<int>(
                                stream: firestoreService
                                    .getPendingTaskRequestsCount(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        '${snapshot.data}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatChip(
                              icon: Icons.format_list_bulleted,
                              label: 'Total',
                              value: tasklist.length.toString(),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatChip(
                              icon: Icons.check_circle,
                              label: 'Completed',
                              value: completedTasksCount.toString(),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatChip(
                              icon: Icons.pending_actions,
                              label: 'Pending',
                              value: (tasklist.length - completedTasksCount)
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: tasklist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: tierProvider.primaryColor.withOpacity(
                                  0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 64,
                                color: tierProvider.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first task',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 100),
                        itemCount: tasklist.length,
                        itemBuilder: (context, index) {
                          final task = tasklist[index];
                          return Todolist(
                            IsChecked: task['isCompleted'] ?? false,
                            TaskName: task['taskName'] ?? '',
                            onChanged: (value) => CheckBoxChanged(value, index),
                            Delete_Fun: (context) => DeleteTask(index),
                            Update_Fun: (context) => UpdateTask(index),
                            hasTimer: task['hasTimer'] ?? false,
                            totalDuration: task['totalDuration'],
                            elapsedSeconds: task['elapsedSeconds'] ?? 0,
                            isRunning: task['isRunning'] ?? false,
                            isSynced: true,
                            onTimerStart: () => _startTimer(index),
                            onTimerPause: () => _pauseTimer(index),
                            onTimerStop: () => _stopTimer(index),
                            assignedByUsername: task['assignedByUsername'],
                            onTimerComplete: () => _autoCompleteTask(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80, right: 3),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: tierProvider.glowColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: NewTask,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
