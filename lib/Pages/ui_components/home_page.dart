import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/Pages/ui_components/friend_components/taskRequestsPage.dart';
import 'package:demo/component/customToast.dart';
import 'package:demo/component/todolist.dart';
import 'package:demo/services/notes/firestore.dart';
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

  bool _isSyncing = false;
  StreamSubscription<QuerySnapshot>? _firebaseSubscription;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startUIUpdateTimer();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    control.dispose();
    timerController.dispose();
    super.dispose();
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

      if (mounted) {
        final tierProvider = context.read<TierThemeProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✨ "${task['taskName']}" completed automatically!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: tierProvider.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error auto-completing task: $e');
      setState(() {
        tasklist[index]['isCompleted'] = false;
        tasklist[index]['completedAt'] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to auto-complete task'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add task. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E5F5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tierProvider.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: control,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Enter your task...',
                  prefixIcon: Icon(
                    Icons.edit,
                    color: tierProvider.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tierProvider.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timer (minutes) - Optional',
                  hintText: 'e.g., 25 for 25 minutes',
                  prefixIcon: Icon(
                    Icons.timer,
                    color: tierProvider.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tierProvider.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      control.clear();
                      timerController.clear();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: Add_Task,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
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
        // Task is being marked as COMPLETE
        tasklist[index]['completedAt'] = Timestamp.now();

        // If task has timer, set elapsed to total duration (fill to max)
        if (task['hasTimer'] == true && task['totalDuration'] != null) {
          tasklist[index]['elapsedSeconds'] = task['totalDuration'];
          tasklist[index]['isRunning'] = false; // Stop timer if running
        }
      } else {
        // Task is being UNCHECKED (marked incomplete)
        tasklist[index]['completedAt'] = null;

        // If task has timer, reset elapsed seconds to 0 (drain water)
        if (task['hasTimer'] == true) {
          tasklist[index]['elapsedSeconds'] = 0;
          tasklist[index]['isRunning'] = false;
          // Increment reset key to trigger water drain animation
          tasklist[index]['resetKey'] = (task['resetKey'] ?? 0) + 1;
        }
      }
    });

    try {
      // Update Firebase with new completion status
      await firestoreService.toggleCompletion(firebaseId, !newCompletedStatus);

      // If task has timer and is being unchecked, update elapsed seconds in Firebase
      if (!newCompletedStatus && task['hasTimer'] == true) {
        await FirebaseFirestore.instance
            .collection('user_notes')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notes')
            .doc(firebaseId)
            .update({'elapsedSeconds': 0, 'isRunning': false});
      }
    } catch (e) {
      print('Error updating Firebase: $e');

      // Revert changes on error
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete task that is not synced'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final deletedTask = tasklist[index];
    setState(() {
      tasklist.removeAt(index);
    });

    try {
      await firestoreService.deleteTask(firebaseId);
    } catch (e) {
      print('Error deleting from Firebase: $e');
      setState(() {
        tasklist.insert(index, deletedTask);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete task. Please try again.'),
            backgroundColor: Colors.red,
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E5F5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Update Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tierProvider.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: control,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: Icon(
                    Icons.edit,
                    color: tierProvider.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tierProvider.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timer (minutes) - Optional',
                  hintText: 'Leave empty to remove timer',
                  prefixIcon: Icon(
                    Icons.timer,
                    color: tierProvider.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tierProvider.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      control.clear();
                      timerController.clear();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierProvider.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final firebaseId = tasklist[index]['firebaseId'];

                        if (firebaseId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please wait for task to sync...'),
                            ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update task.'),
                                backgroundColor: Colors.red,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
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
