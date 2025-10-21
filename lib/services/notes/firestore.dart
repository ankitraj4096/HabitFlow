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
  Future<String?> addTask(bool isCompleted, String taskName, [int? durationMins]) async {
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
  Future<void> updateTask(String docID, bool isCompleted, String taskName, [int? durationMins]) async {
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
  Future<void> toggleTimer(String docId, bool isRunning, int elapsedSeconds) async {
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
}
