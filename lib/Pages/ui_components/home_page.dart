import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/Pages/ui_components/friend_components/taskRequestsPage.dart';
import 'package:demo/component/todolist.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final mybox = Hive.box('mybox');
  List<Map<String, dynamic>> tasklist = [];
  final TextEditingController control = TextEditingController();
  final TextEditingController timerController = TextEditingController();

  final FireStoreService firestoreService = FireStoreService();

  bool _isSyncing = false;
  StreamSubscription<QuerySnapshot>? _firebaseSubscription;
  Set<String> _pendingSyncIds = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    control.dispose();
    timerController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isSyncing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _loadLocalData();
        _listenToFirebaseChanges();
        await _syncPendingChangesToFirebase();
      } else {
        _loadLocalData();
      }
    } catch (e) {
      print('Error initializing data: $e');
      _loadLocalData();
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _loadLocalData() {
    final data = mybox.get("ToDoList");
    if (data != null && data is List) {
      tasklist = List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item)),
      );
    } else {
      tasklist = [];
    }
    setState(() {});
  }

  void _saveLocalData() {
    mybox.put("ToDoList", tasklist);
  }

  void _listenToFirebaseChanges() {
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
          if (status == 'pending') {
            continue;
          }

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

          updatedTasks.add({
            'firebaseId': doc.id,
            'isCompleted': isCompleted,
            'taskName': data['taskName'] ?? '',
            'hasTimer': data['hasTimer'] ?? false,
            'totalDuration': data['totalDuration'],
            'elapsedSeconds': data['elapsedSeconds'] ?? 0,
            'isRunning': data['isRunning'] ?? false,
            'lastUpdated': data['lastUpdated'],
            'completedAt': data['completedAt'],
            'isSynced': true,
            'assignedByUserID': data['assignedByUserID'],
            'assignedByUsername': data['assignedByUsername'],
            'status': status ?? 'accepted',
          });
        }

        setState(() {
          tasklist = updatedTasks;
        });

        _saveLocalData();
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
      tasklist[index]['isSynced'] = false;
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

  Future<void> _syncPendingChangesToFirebase() async {
    try {
      final pendingTasks = tasklist
          .where(
            (task) => task['isSynced'] != true || task['firebaseId'] == null,
          )
          .toList();

      for (var task in pendingTasks) {
        if (task['firebaseId'] == null) {
          final timerMinutes = task['totalDuration'] != null
              ? (task['totalDuration'] / 60).round()
              : null;

          final firebaseId = await firestoreService.addTask(
            task['isCompleted'] ?? false,
            task['taskName'] ?? '',
            timerMinutes,
          );

          if (firebaseId != null) {
            task['firebaseId'] = firebaseId;
            task['isSynced'] = true;
          }
        }
      }

      _saveLocalData();
    } catch (e) {
      print('Error syncing pending changes: $e');
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

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      tasklist.add({
        'tempId': tempId,
        'isCompleted': false,
        'taskName': taskName,
        'firebaseId': null,
        'hasTimer': timerMinutes != null && timerMinutes > 0,
        'totalDuration': timerMinutes != null ? timerMinutes * 60 : null,
        'elapsedSeconds': 0,
        'isRunning': false,
        'isSynced': false,
        'assignedByUserID': null,
        'assignedByUsername': null,
        'status': 'accepted',
      });
      _pendingSyncIds.add(tempId);
    });

    try {
      final firebaseId = await firestoreService.addTask(
        false,
        taskName,
        timerMinutes,
      );

      if (firebaseId != null) {
        setState(() {
          tasklist.removeWhere((task) => task['tempId'] == tempId);
          _pendingSyncIds.remove(tempId);
        });
        _saveLocalData();
      } else {
        final index = tasklist.indexWhere((task) => task['tempId'] == tempId);
        if (index != -1) {
          setState(() {
            tasklist[index]['isSynced'] = false;
          });
          _saveLocalData();
        }
      }
    } catch (e) {
      print('Error adding to Firebase: $e');
      final index = tasklist.indexWhere((task) => task['tempId'] == tempId);
      if (index != -1) {
        setState(() {
          tasklist[index]['isSynced'] = false;
        });
        _saveLocalData();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sync task. Will retry later.'),
          backgroundColor: Colors.orange,
        ),
      );
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
                    child: const Icon(Icons.add_task, color: Colors.white, size: 24),
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
                  prefixIcon: Icon(Icons.edit, color: tierProvider.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tierProvider.primaryColor, width: 2),
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
                  prefixIcon: Icon(Icons.timer, color: tierProvider.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tierProvider.primaryColor, width: 2),
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
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for task to sync...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final newCompletedStatus = !tasklist[index]['isCompleted'];

    setState(() {
      tasklist[index]['isCompleted'] = newCompletedStatus;
      tasklist[index]['isSynced'] = false;

      if (newCompletedStatus) {
        tasklist[index]['completedAt'] = Timestamp.now();
      } else {
        tasklist[index]['completedAt'] = null;
      }
    });

    try {
      await firestoreService.toggleCompletion(firebaseId, !newCompletedStatus);
    } catch (e) {
      print('Error updating Firebase: $e');
      setState(() {
        tasklist[index]['isCompleted'] = !newCompletedStatus;
        tasklist[index]['completedAt'] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void DeleteTask(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];

    final deletedTask = tasklist[index];
    setState(() {
      tasklist.removeAt(index);
    });
    _saveLocalData();

    if (firebaseId != null) {
      try {
        await firestoreService.deleteTask(firebaseId);
      } catch (e) {
        print('Error deleting from Firebase: $e');
        setState(() {
          tasklist.insert(index, deletedTask);
        });
        _saveLocalData();

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
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
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
                  prefixIcon: Icon(Icons.edit, color: tierProvider.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tierProvider.primaryColor, width: 2),
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
                  prefixIcon: Icon(Icons.timer, color: tierProvider.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tierProvider.primaryColor, width: 2),
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

                        setState(() {
                          tasklist[index]['taskName'] = control.text;
                          tasklist[index]['hasTimer'] =
                              timerMinutes != null && timerMinutes > 0;
                          tasklist[index]['totalDuration'] = timerMinutes != null
                              ? timerMinutes * 60
                              : null;
                          tasklist[index]['isSynced'] = false;
                        });

                        Navigator.of(context).pop();
                        control.clear();
                        timerController.clear();

                        try {
                          await firestoreService.updateTask(
                            firebaseId,
                            tasklist[index]['isCompleted'],
                            tasklist[index]['taskName'],
                            timerMinutes,
                          );
                        } catch (e) {
                          print('Error updating Firebase: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to update task. Changes saved locally.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
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
                                  if (_isSyncing ||
                                      _pendingSyncIds.isNotEmpty) ...[
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
                                color: tierProvider.primaryColor.withOpacity(0.1),
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
                            isSynced: task['isSynced'] ?? true,
                            onTimerToggle: () => _toggleTimer(index),
                            onTimerReset: () => _resetTimer(index),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  void _toggleTimer(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];

    if (firebaseId == null) return;

    setState(() {
      tasklist[index]['isRunning'] = !tasklist[index]['isRunning'];
      tasklist[index]['isSynced'] = false;
    });

    try {
      await firestoreService.toggleTimer(
        firebaseId,
        !task['isRunning'],
        task['elapsedSeconds'] ?? 0,
      );
    } catch (e) {
      print('Error toggling timer: $e');
    }
  }

  void _resetTimer(int index) async {
    final firebaseId = tasklist[index]['firebaseId'];

    if (firebaseId == null) return;

    setState(() {
      tasklist[index]['isRunning'] = false;
      tasklist[index]['elapsedSeconds'] = 0;
      tasklist[index]['isSynced'] = false;
    });

    try {
      await firestoreService.resetTimer(firebaseId);
    } catch (e) {
      print('Error resetting timer: $e');
    }
  }
}
