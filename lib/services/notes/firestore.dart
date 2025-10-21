import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Ensure the user document exists
      await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(user.uid)
          .set({}, SetOptions(merge: true));

      final Map<String, dynamic> taskData = {
        'isCompleted': isCompleted,
        'taskName': taskName,
        'timestamp': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      };

      // Add timer data if duration is provided
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

  /// Returns a stream of the current user's tasks
  Stream<QuerySnapshot> getTasksStream() {
    try {
      return _userNotes.orderBy('timestamp', descending: false).snapshots();
    } catch (e) {
      print('Error getting tasks stream: $e');
      return Stream.empty();
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
        // PAUSE: Save elapsed time
        await docRef.update({
          'isRunning': false,
          'startTime': FieldValue.delete(),
          'elapsedSeconds': elapsedSeconds,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // START: Begin/resume timer
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

  /// Get user statistics - FIXED: Now uses 'timestamp' consistently
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final snapshot = await _userNotes.get();

      int totalTasks = snapshot.docs.length;
      int completedTasks = 0;
      int totalHours = 0;
      Map<String, int> completionsByDate = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Count completed tasks
        if (data['isCompleted'] == true) {
          completedTasks++;

          // FIXED: Use 'timestamp' (creation date) not 'lastUpdated'
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final dateKey = _formatDate(timestamp.toDate());
            completionsByDate[dateKey] = (completionsByDate[dateKey] ?? 0) + 1;
            
            // Debug print
            print('Task completed on $dateKey, new count: ${completionsByDate[dateKey]}');
          }
        }

        // Calculate total hours from timer tasks
        if (data['hasTimer'] == true && data['elapsedSeconds'] != null) {
          totalHours += (data['elapsedSeconds'] as int) ~/ 3600;
        }
      }

      // Debug print
      print('Total completions by date: $completionsByDate');

      // Calculate current streak
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

  /// Get heatmap data stream - FIXED: Uses 'timestamp' consistently
  Stream<Map<String, int>> getHeatmapData() {
    return _userNotes
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> heatmap = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // FIXED: Use 'timestamp' consistently
        final ts = data['timestamp'] as Timestamp?;
        if (ts != null) {
          final d = ts.toDate();
          final key = _formatDate(d);
          heatmap[key] = (heatmap[key] ?? 0) + 1;
          
          // Debug print
          print('Heatmap: $key -> ${heatmap[key]}');
        }
      }
      
      print('Final heatmap data: $heatmap');
      return heatmap;
    });
  }

  /// Format date for heatmap (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate current streak of consecutive days with completions
  int _calculateStreak(Map<String, int> completionsByDate) {
    if (completionsByDate.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;

    // Check backwards from today
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateKey = _formatDate(checkDate);

      if (completionsByDate.containsKey(dateKey)) {
        streak++;
      } else {
        // If we've already started counting and hit a gap, stop
        if (streak > 0) break;
        // If it's the first day (today) and no completion, allow one day grace
        if (i == 0) continue;
        break;
      }
    }

    return streak;
  }

  /// Get username from Firestore users collection
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

  /// Get user level based on completed tasks
  int getUserLevel(int completedTasks) {
    // Level up every 10 completed tasks
    return (completedTasks ~/ 10) + 1;
  }
}
