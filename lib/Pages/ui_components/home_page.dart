import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/component/dialogbox.dart';
import 'package:demo/component/todolist.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  // Firestore
  final FireStoreService firestoreService = FireStoreService();
  
  bool _isSyncing = false;
  StreamSubscription<QuerySnapshot>? _firebaseSubscription;
  
  // Track pending sync operations
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

  /// Initialize data - Firebase is single source of truth
  Future<void> _initializeData() async {
    setState(() => _isSyncing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Load local data first for immediate display
        _loadLocalData();
        
        // Start listening to Firebase stream (single source of truth)
        _listenToFirebaseChanges();
        
        // Sync any pending local changes to Firebase
        await _syncPendingChangesToFirebase();
      } else {
        // No user logged in, just load local data
        _loadLocalData();
      }
    } catch (e) {
      print('Error initializing data: $e');
      _loadLocalData();
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  /// Load data from local Hive storage
  void _loadLocalData() {
    final data = mybox.get("ToDoList");
    if (data != null && data is List) {
      tasklist = List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item))
      );
    } else {
      tasklist = [];
    }
    setState(() {});
  }

  /// Save data to local Hive storage
  void _saveLocalData() {
    mybox.put("ToDoList", tasklist);
  }

  /// Listen to Firebase changes - THIS IS THE SINGLE SOURCE OF TRUTH
  void _listenToFirebaseChanges() {
    _firebaseSubscription?.cancel();
    
    _firebaseSubscription = firestoreService.getTasksStream().listen(
      (snapshot) {
        // Convert Firebase data to local format
        List<Map<String, dynamic>> updatedTasks = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          updatedTasks.add({
            'firebaseId': doc.id,
            'isCompleted': data['isCompleted'] ?? false,
            'taskName': data['taskName'] ?? '',
            'hasTimer': data['hasTimer'] ?? false,
            'totalDuration': data['totalDuration'],
            'elapsedSeconds': data['elapsedSeconds'] ?? 0,
            'isRunning': data['isRunning'] ?? false,
            'lastUpdated': data['lastUpdated'],
            'isSynced': true, // Data from Firebase is always synced
          });
        }

        // Update local list with Firebase data
        setState(() {
          tasklist = updatedTasks;
        });
        
        // Save to local storage
        _saveLocalData();
      },
      onError: (error) {
        print('Error listening to Firebase: $error');
      },
    );
  }

  /// Sync pending local changes to Firebase
  Future<void> _syncPendingChangesToFirebase() async {
    try {
      // Find tasks that are not synced
      final pendingTasks = tasklist.where((task) => 
        task['isSynced'] != true || task['firebaseId'] == null
      ).toList();

      for (var task in pendingTasks) {
        if (task['firebaseId'] == null) {
          // Task doesn't exist in Firebase, create it
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

  /// Add a new task - Firebase first, then local
  void Add_Task() async {
    if (control.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final taskName = control.text;
    final timerMinutes = timerController.text.isNotEmpty 
        ? int.tryParse(timerController.text) 
        : null;

    // Close dialog immediately for better UX
    Navigator.of(context).pop();
    control.clear();
    timerController.clear();

    // Show temporary item with sync indicator
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
        'isSynced': false, // Not synced yet
      });
      _pendingSyncIds.add(tempId);
    });

    // Try to add to Firebase
    try {
      final firebaseId = await firestoreService.addTask(false, taskName, timerMinutes);
      
      if (firebaseId != null) {
        // Remove temp item - Firebase stream will add the real one
        setState(() {
          tasklist.removeWhere((task) => task['tempId'] == tempId);
          _pendingSyncIds.remove(tempId);
        });
        _saveLocalData();
      } else {
        // Failed to add to Firebase, mark as needs sync
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
      // Keep local copy with sync status false
      final index = tasklist.indexWhere((task) => task['tempId'] == tempId);
      if (index != -1) {
        setState(() {
          tasklist[index]['isSynced'] = false;
        });
        _saveLocalData();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync task. Will retry later.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Show dialog to add new task
  void NewTask() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_task, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Task name input
              TextField(
                controller: control,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Enter your task...',
                  prefixIcon: Icon(Icons.edit, color: Color(0xFF7C4DFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Timer input (optional)
              TextField(
                controller: timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timer (minutes) - Optional',
                  hintText: 'e.g., 25 for 25 minutes',
                  prefixIcon: Icon(Icons.timer, color: Color(0xFF448AFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF448AFF), width: 2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Buttons
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
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: Add_Task,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C4DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggle checkbox for a task
  void CheckBoxChanged(bool? value, int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    
    if (firebaseId == null) {
      // Can't update if not synced to Firebase yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for task to sync...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // Optimistically update UI
    setState(() {
      tasklist[index]['isCompleted'] = !tasklist[index]['isCompleted'];
      tasklist[index]['isSynced'] = false; // Mark as pending sync
    });

    // Try to update Firebase
    try {
      await firestoreService.toggleCompletion(
        firebaseId,
        !tasklist[index]['isCompleted'],
      );
      // Firebase stream will update with synced status
    } catch (e) {
      print('Error updating Firebase: $e');
      // Revert change
      setState(() {
        tasklist[index]['isCompleted'] = !tasklist[index]['isCompleted'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Delete a task
  void DeleteTask(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    
    // Remove from UI immediately
    final deletedTask = tasklist[index];
    setState(() {
      tasklist.removeAt(index);
    });
    _saveLocalData();

    // Try to delete from Firebase
    if (firebaseId != null) {
      try {
        await firestoreService.deleteTask(firebaseId);
      } catch (e) {
        print('Error deleting from Firebase: $e');
        
        // Restore task if deletion failed
        setState(() {
          tasklist.insert(index, deletedTask);
        });
        _saveLocalData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update a task
  void UpdateTask(int index) {
    final task = tasklist[index];
    control.text = task['taskName'];
    
    if (task['hasTimer'] == true && task['totalDuration'] != null) {
      timerController.text = (task['totalDuration'] / 60).round().toString();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Update Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              TextField(
                controller: control,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: Icon(Icons.edit, color: Color(0xFF7C4DFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              TextField(
                controller: timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timer (minutes) - Optional',
                  hintText: 'Leave empty to remove timer',
                  prefixIcon: Icon(Icons.timer, color: Color(0xFF448AFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF448AFF), width: 2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
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
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final firebaseId = tasklist[index]['firebaseId'];
                      
                      if (firebaseId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please wait for task to sync...')),
                        );
                        return;
                      }

                      final timerMinutes = timerController.text.isNotEmpty 
                          ? int.tryParse(timerController.text) 
                          : null;

                      // Optimistically update UI
                      setState(() {
                        tasklist[index]['taskName'] = control.text;
                        tasklist[index]['hasTimer'] = timerMinutes != null && timerMinutes > 0;
                        tasklist[index]['totalDuration'] = timerMinutes != null ? timerMinutes * 60 : null;
                        tasklist[index]['isSynced'] = false;
                      });

                      Navigator.of(context).pop();
                      control.clear();
                      timerController.clear();

                      // Update Firebase
                      try {
                        await firestoreService.updateTask(
                          firebaseId,
                          tasklist[index]['isCompleted'],
                          tasklist[index]['taskName'],
                          timerMinutes,
                        );
                        // Firebase stream will update with synced status
                      } catch (e) {
                        print('Error updating Firebase: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update task. Changes saved locally.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C4DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Update', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5),
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7C4DFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
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
                              Text(
                                'Task List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Stay organized and productive 📝',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_isSyncing || _pendingSyncIds.isNotEmpty) ...[
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.checklist_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Progress Stats
                      Container(
                        padding: EdgeInsets.all(16),
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
                              value: (tasklist.length - completedTasksCount).toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Task List
              Expanded(
                child: tasklist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Color(0xFF7C4DFF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Color(0xFF7C4DFF),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'No tasks yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
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
                        padding: EdgeInsets.only(top: 20, bottom: 100),
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80,right: 3),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF7C4DFF).withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: NewTask,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(Icons.add, size: 32),
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
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // Timer methods
  void _toggleTimer(int index) async {
    final task = tasklist[index];
    final firebaseId = task['firebaseId'];
    
    if (firebaseId == null) return;
    
    // Update local state
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
