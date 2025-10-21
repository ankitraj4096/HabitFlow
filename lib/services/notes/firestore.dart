import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class FireStoreService {
  /// Returns a reference to the current user's notes collection
  CollectionReference get _userNotes {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return FirebaseFirestore.instance
        .collection('user_notes')
        .doc(user.uid)
        .collection('notes');
  }

  /// Adds a new task to Firebase
  Future<String?> addTask(
    bool isCompleted,
    String taskName, [
    int? durationMins,
  ]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(user.uid)
          .set({}, SetOptions(merge: true));

      final Map<String, dynamic> taskData = {
        'isCompleted': isCompleted,
        'taskName': taskName,
        'timestamp': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        // NEW: Track assignment status
        'assignedByUserID': null,
        'assignedByUsername': null,
        'status': 'accepted', // Self-created tasks are auto-accepted
      };

      if (durationMins != null && durationMins > 0) {
        taskData.addAll({
          'hasTimer': true,
          'isRunning': false,
          'elapsedSeconds': 0,
          'totalDuration': durationMins * 60,
        });
      } else {
        taskData['hasTimer'] = false;
      }

      final docRef = await _userNotes.add(taskData);
      return docRef.id;
    } catch (e) {
      print('Error adding task to Firebase: $e');
      return null;
    }
  }

  /// NEW: Assign a task to a friend
  Future<String?> assignTaskToFriend({
    required String friendUserID,
    required String taskName,
    int? durationMins,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final currentUsername = await getUsername();

      // Ensure friend's user document exists
      await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(friendUserID)
          .set({}, SetOptions(merge: true));

      final Map<String, dynamic> taskData = {
        'isCompleted': false,
        'taskName': taskName,
        'timestamp': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        // NEW: Track who assigned this task
        'assignedByUserID': user.uid,
        'assignedByUsername': currentUsername,
        'status': 'pending', // Requires approval
      };

      if (durationMins != null && durationMins > 0) {
        taskData.addAll({
          'hasTimer': true,
          'isRunning': false,
          'elapsedSeconds': 0,
          'totalDuration': durationMins * 60,
        });
      } else {
        taskData['hasTimer'] = false;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(friendUserID)
          .collection('notes')
          .add(taskData);

      return docRef.id;
    } catch (e) {
      print('Error assigning task to friend: $e');
      return null;
    }
  }

  /// NEW: Get count of pending task requests
  Stream<int> getPendingTaskRequestsCount() {
    try {
      return _userNotes
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error getting pending task requests count: $e');
      return Stream.value(0);
    }
  }

  /// NEW: Get stream of pending task requests
  Stream<QuerySnapshot> getPendingTaskRequestsStream() {
    try {
      return _userNotes
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting pending task requests: $e');
      return Stream.empty();
    }
  }

  /// NEW: Accept a task request (change status from pending to accepted)
  Future<void> acceptTaskRequest(String docID) async {
    try {
      await _userNotes.doc(docID).update({
        'status': 'accepted',
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      print('Error accepting task request: $e');
      rethrow;
    }
  }

  /// NEW: Decline a task request (delete the task)
  Future<void> declineTaskRequest(String docID) async {
    try {
      await _userNotes.doc(docID).delete();
    } catch (e) {
      print('Error declining task request: $e');
      rethrow;
    }
  }

  /// Returns a stream of the current user's ACCEPTED tasks only
  Stream<QuerySnapshot> getTasksStream() {
    try {
      return _userNotes
          .where('status', isEqualTo: 'accepted')
          .orderBy('timestamp', descending: false)
          .snapshots();
    } catch (e) {
      print('Error getting tasks stream: $e');
      return Stream.empty();
    }
  }

  /// NEW: Get tasks for a specific user (for viewing friend's tasks)
  Stream<QuerySnapshot> getTasksStreamForUser(String userID) {
    try {
      return FirebaseFirestore.instance
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('status', isEqualTo: 'accepted')
          .orderBy('timestamp', descending: false)
          .snapshots();
    } catch (e) {
      print('Error getting tasks stream for user: $e');
      return Stream.empty();
    }
  }

  /// Updates a task in Firebase
  Future<void> updateTask(
    String docID,
    bool isCompleted,
    String taskName, [
    int? durationMins,
  ]) async {
    try {
      final Map<String, dynamic> updateData = {
        'isCompleted': isCompleted,
        'taskName': taskName,
        'lastUpdated': Timestamp.now(),
      };

      if (durationMins != null && durationMins > 0) {
        updateData.addAll({
          'hasTimer': true,
          'totalDuration': durationMins * 60,
        });
      } else {
        updateData['hasTimer'] = false;
        updateData['totalDuration'] = FieldValue.delete();
        updateData['isRunning'] = FieldValue.delete();
        updateData['elapsedSeconds'] = FieldValue.delete();
        updateData['startTime'] = FieldValue.delete();
      }

      await _userNotes.doc(docID).update(updateData);
    } catch (e) {
      print('Error updating task in Firebase: $e');
      rethrow;
    }
  }

  /// Deletes a task from Firebase
  Future<void> deleteTask(String docID) async {
    try {
      await _userNotes.doc(docID).delete();
    } catch (e) {
      print('Error deleting task from Firebase: $e');
      rethrow;
    }
  }

  /// Toggle task completion status
  Future<void> toggleCompletion(String docID, bool currentStatus) async {
    try {
      await _userNotes.doc(docID).update({
        'isCompleted': !currentStatus,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      print('Error toggling completion in Firebase: $e');
      rethrow;
    }
  }

  /// Starts or pauses the timer on a task
  Future<void> toggleTimer(
    String docId,
    bool isRunning,
    int elapsedSeconds,
  ) async {
    try {
      final docRef = _userNotes.doc(docId);

      if (isRunning) {
        await docRef.update({
          'isRunning': false,
          'startTime': FieldValue.delete(),
          'elapsedSeconds': elapsedSeconds,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        await docRef.update({
          'isRunning': true,
          'startTime': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error toggling timer in Firebase: $e');
      rethrow;
    }
  }

  /// Stops and resets the timer for a task
  Future<void> resetTimer(String docId) async {
    try {
      await _userNotes.doc(docId).update({
        'isRunning': false,
        'startTime': FieldValue.delete(),
        'elapsedSeconds': 0,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      print('Error resetting timer in Firebase: $e');
      rethrow;
    }
  }

  /// Get user statistics (only counts accepted tasks)
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final snapshot = await _userNotes
          .where('status', isEqualTo: 'accepted')
          .get();

      int totalTasks = snapshot.docs.length;
      int completedTasks = 0;
      int totalHours = 0;
      Map<String, int> completionsByDate = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['isCompleted'] == true) {
          completedTasks++;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final dateKey = _formatDate(timestamp.toDate());
            completionsByDate[dateKey] = (completionsByDate[dateKey] ?? 0) + 1;
          }
        }

        if (data['hasTimer'] == true && data['elapsedSeconds'] != null) {
          totalHours += (data['elapsedSeconds'] as int) ~/ 3600;
        }
      }

      int currentStreak = _calculateStreak(completionsByDate);

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalHours': totalHours,
        'currentStreak': currentStreak,
        'completionsByDate': completionsByDate,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHours': 0,
        'currentStreak': 0,
        'completionsByDate': {},
      };
    }
  }

  /// Get heatmap data stream (only accepted tasks)
  Stream<Map<String, int>> getHeatmapData() {
    return _userNotes
        .where('status', isEqualTo: 'accepted')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> heatmap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['timestamp'] as Timestamp?;
        if (ts != null) {
          final d = ts.toDate();
          final key = _formatDate(d);
          heatmap[key] = (heatmap[key] ?? 0) + 1;
        }
      }
      return heatmap;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateStreak(Map<String, int> completionsByDate) {
    if (completionsByDate.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateKey = _formatDate(checkDate);
      if (completionsByDate.containsKey(dateKey)) {
        streak++;
      } else {
        if (streak > 0) break;
        if (i == 0) continue;
        break;
      }
    }
    return streak;
  }

  Future<String> getUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'User';
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data()?['username'] ?? 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  /// Get user tier based on completed tasks
  Map<String, dynamic> getUserTier(int completedTasks) {
    final List<Map<String, dynamic>> tiers = [
      {"id": 1, "name": "The Initiate", "completedTasks": 1, "icon": "sparkles", "gradient": [Colors.grey, Colors.grey.shade700], "glow": Colors.grey},
      {"id": 2, "name": "The Seeker", "completedTasks": 5, "icon": "target", "gradient": [Colors.blue.shade400, Colors.blue.shade600], "glow": Colors.blue},
      {"id": 3, "name": "The Novice", "completedTasks": 10, "icon": "book", "gradient": [Colors.green.shade400, Colors.green.shade600], "glow": Colors.green},
      {"id": 4, "name": "The Apprentice", "completedTasks": 25, "icon": "hammer", "gradient": [Colors.yellow.shade400, Colors.yellow.shade600], "glow": Colors.yellow},
      {"id": 5, "name": "The Adept", "completedTasks": 50, "icon": "zap", "gradient": [Colors.orange.shade400, Colors.orange.shade600], "glow": Colors.orange},
      {"id": 6, "name": "The Disciplined", "completedTasks": 100, "icon": "shield", "gradient": [Colors.purple.shade400, Colors.purple.shade600], "glow": Colors.purple},
      {"id": 7, "name": "The Specialist", "completedTasks": 250, "icon": "award", "gradient": [Colors.pink.shade400, Colors.pink.shade600], "glow": Colors.pink},
      {"id": 8, "name": "The Expert", "completedTasks": 500, "icon": "crown", "gradient": [Colors.indigo.shade400, Colors.indigo.shade600], "glow": Colors.indigo},
      {"id": 9, "name": "The Vanguard", "completedTasks": 1000, "icon": "flame", "gradient": [Colors.red.shade400, Colors.red.shade600], "glow": Colors.red},
      {"id": 10, "name": "The Sentinel", "completedTasks": 1750, "icon": "eye", "gradient": [Colors.cyan.shade400, Colors.cyan.shade600], "glow": Colors.cyan},
      {"id": 11, "name": "The Virtuoso", "completedTasks": 2500, "icon": "music", "gradient": [Colors.teal.shade400, Colors.teal.shade600], "glow": Colors.teal},
      {"id": 12, "name": "The Master", "completedTasks": 4000, "icon": "trophy", "gradient": [Colors.amber.shade400, Colors.amber.shade600], "glow": Colors.amber},
      {"id": 13, "name": "The Grandmaster", "completedTasks": 6000, "icon": "gem", "gradient": [Colors.green.shade400, Colors.green.shade600], "glow": Colors.green},
      {"id": 14, "name": "The Titan", "completedTasks": 8000, "icon": "mountain", "gradient": [Colors.blueGrey.shade400, Colors.blueGrey.shade700], "glow": Colors.blueGrey},
      {"id": 15, "name": "The Luminary", "completedTasks": 10000, "icon": "sun", "gradient": [Colors.yellow.shade300, Colors.orange.shade400, Colors.red.shade500], "glow": Colors.orange},
      {"id": 16, "name": "The Ascended", "completedTasks": 10001, "icon": "infinity", "gradient": [Colors.purple.shade400, Colors.pink.shade500, Colors.yellow.shade400], "glow": Colors.purple, "animated": true},
    ];

    Map<String, dynamic> currentTier = tiers[0];
    for (final tier in tiers) {
      if (completedTasks >= tier['completedTasks']) {
        currentTier = tier;
      } else {
        break;
      }
    }
    return currentTier;
  }

  IconData getIconFromString(String iconName) {
    final iconMap = {
      'sparkles': LucideIcons.sparkles,
      'target': LucideIcons.target,
      'book': LucideIcons.book,
      'hammer': LucideIcons.hammer,
      'zap': LucideIcons.zap,
      'shield': LucideIcons.shield,
      'award': LucideIcons.award,
      'crown': LucideIcons.crown,
      'flame': LucideIcons.flame,
      'eye': LucideIcons.eye,
      'music': LucideIcons.music,
      'trophy': LucideIcons.trophy,
      'gem': LucideIcons.gem,
      'mountain': LucideIcons.mountain,
      'sun': LucideIcons.sun,
      'infinity': LucideIcons.infinity,
    };
    return iconMap[iconName] ?? LucideIcons.star;
  }

  /// Get statistics for a specific user (only accepted tasks)
  Future<Map<String, dynamic>> getUserStatisticsForUser(String userID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('status', isEqualTo: 'accepted')
          .get();

      int totalTasks = snapshot.docs.length;
      int completedTasks = 0;
      int totalHours = 0;
      Map<String, int> completionsByDate = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isCompleted'] == true) {
          completedTasks++;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final dateKey = _formatDate(timestamp.toDate());
            completionsByDate[dateKey] = (completionsByDate[dateKey] ?? 0) + 1;
          }
        }
        if (data['hasTimer'] == true && data['elapsedSeconds'] != null) {
          totalHours += (data['elapsedSeconds'] as int) ~/ 3600;
        }
      }

      int currentStreak = _calculateStreak(completionsByDate);

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalHours': totalHours,
        'currentStreak': currentStreak,
        'completionsByDate': completionsByDate,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHours': 0,
        'currentStreak': 0,
        'completionsByDate': {},
      };
    }
  }

  /// Get heatmap data for a specific user (only accepted tasks)
  Stream<Map<String, int>> getHeatmapDataForUser(String userID) {
    return FirebaseFirestore.instance
        .collection('user_notes')
        .doc(userID)
        .collection('notes')
        .where('status', isEqualTo: 'accepted')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> heatmap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        if (ts != null) {
          final d = ts.toDate();
          final key = _formatDate(d);
          heatmap[key] = (heatmap[key] ?? 0) + 1;
        }
      }
      return heatmap;
    });
  }
}
