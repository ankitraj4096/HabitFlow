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

  /// ✅ Get reference to recurring history for a specific task
  CollectionReference _getTaskHistoryRef(String taskId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return FirebaseFirestore.instance
        .collection('recurringHistory')
        .doc(user.uid)
        .collection(taskId)
        .doc('completions')
        .collection('dates');
  }

  /// ✅ Adds a new task to Firebase with recurring support
  Future<String?> addTask(
    bool isCompleted,
    String taskName, [
    int? durationMins,
    bool isRecurring = false,
  ]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(user.uid)
          .set({}, SetOptions(merge: true));

      final now = DateTime.now();
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final Map<String, dynamic> taskData = {
        'isCompleted': isCompleted,
        'taskName': taskName,
        'timestamp': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        'assignedByUserID': null,
        'assignedByUsername': null,
        'status': 'accepted',
        'isRecurring': isRecurring,
        'completedToday': isCompleted && isRecurring ? todayDate : null,
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

      // ✅ If recurring and completed, save to history
      if (isRecurring && isCompleted) {
        await _saveCompletionToHistory(docRef.id, taskData);
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding task to Firebase: $e');
      return null;
    }
  }

  /// ✅ Save task completion to history
  Future<void> _saveCompletionToHistory(
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    try {
      final now = DateTime.now();
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _getTaskHistoryRef(taskId).doc(todayDate).set({
        'completedAt': Timestamp.now(),
        'taskName': taskData['taskName'],
        'duration': taskData['elapsedSeconds'] ?? 0,
        'totalDuration': taskData['totalDuration'] ?? 0,
      }, SetOptions(merge: true)); // ✅ Use merge to avoid overwriting

      debugPrint('✅ Saved completion to history: $taskId on $todayDate');
    } catch (e) {
      debugPrint('❌ Error saving to history: $e');
    }
  }

  /// Assign a task to a friend
  Future<String?> assignTaskToFriend({
    required String friendUserID,
    required String taskName,
    int? durationMins,
    bool isRecurring = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final currentUsername = await getUsername();

      await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(friendUserID)
          .set({}, SetOptions(merge: true));

      final Map<String, dynamic> taskData = {
        'isCompleted': false,
        'taskName': taskName,
        'timestamp': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        'assignedByUserID': user.uid,
        'assignedByUsername': currentUsername,
        'status': 'pending',
        'isRecurring': isRecurring,
        'completedToday': null,
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
      debugPrint('Error assigning task to friend: $e');
      return null;
    }
  }

  /// Get count of pending task requests
  Stream<int> getPendingTaskRequestsCount() {
    try {
      return _userNotes
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('Error getting pending task requests count: $e');
      return Stream.value(0);
    }
  }

  /// Get stream of pending task requests
  Stream<QuerySnapshot> getPendingTaskRequestsStream() {
    try {
      return _userNotes.where('status', isEqualTo: 'pending').snapshots();
    } catch (e) {
      debugPrint('Error getting pending task requests: $e');
      return Stream.empty();
    }
  }

  /// Accept a task request
  Future<void> acceptTaskRequest(String docID) async {
    try {
      await _userNotes.doc(docID).update({
        'status': 'accepted',
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error accepting task request: $e');
      rethrow;
    }
  }

  /// Decline a task request
  Future<void> declineTaskRequest(String docID) async {
    try {
      await _userNotes.doc(docID).delete();
    } catch (e) {
      debugPrint('Error declining task request: $e');
      rethrow;
    }
  }

  /// Get tasks stream
  Stream<QuerySnapshot> getTasksStream() {
    try {
      return _userNotes.orderBy('timestamp', descending: false).snapshots();
    } catch (e) {
      debugPrint('Error getting tasks stream: $e');
      return Stream.empty();
    }
  }

  /// Get tasks for a specific user
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
      debugPrint('Error getting tasks stream for user: $e');
      return Stream.empty();
    }
  }

  /// ✅ Updates a task in Firebase with recurring support
  Future<void> updateTask(
    String docID,
    bool isCompleted,
    String taskName, [
    int? durationMins,
    bool? isRecurring,
  ]) async {
    try {
      final now = DateTime.now();
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final Map<String, dynamic> updateData = {
        'isCompleted': isCompleted,
        'taskName': taskName,
        'lastUpdated': Timestamp.now(),
      };

      // ✅ Update recurring status if provided
      if (isRecurring != null) {
        updateData['isRecurring'] = isRecurring;
      }

      // ✅ Track if completed today
      if (isCompleted) {
        updateData['completedToday'] = todayDate;
      } else {
        updateData['completedToday'] = null;
      }

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

      // ✅ Save to history if recurring and completed
      final taskDoc = await _userNotes.doc(docID).get();
      final taskData = taskDoc.data() as Map<String, dynamic>?;

      if (taskData != null && taskData['isRecurring'] == true && isCompleted) {
        await _saveCompletionToHistory(docID, taskData);
      }
    } catch (e) {
      debugPrint('Error updating task in Firebase: $e');
      rethrow;
    }
  }

  /// Deletes a task from Firebase
  Future<void> deleteTask(String docID) async {
    try {
      await _userNotes.doc(docID).delete();
    } catch (e) {
      debugPrint('Error deleting task from Firebase: $e');
      rethrow;
    }
  }

  /// ✅ Delete task with optional history preservation
  Future<void> deleteTaskWithHistory(
    String docID, {
    bool deleteHistory = false,
  }) async {
    try {
      await _userNotes.doc(docID).delete();

      if (deleteHistory) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final historyRef = FirebaseFirestore.instance
              .collection('recurringHistory')
              .doc(user.uid)
              .collection(docID);

          final docs = await historyRef.get();
          for (var doc in docs.docs) {
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  /// Toggle task completion status
  Future<void> toggleCompletion(String docID, bool currentStatus) async {
    try {
      final now = DateTime.now();
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // ✅ FETCH TASK DATA FIRST (before updating)
      final taskDoc = await _userNotes.doc(docID).get();
      final taskData = taskDoc.data() as Map<String, dynamic>?;
      final isRecurringTask = taskData?['isRecurring'] == true;

      final Map<String, dynamic> updateData = {
        'isCompleted': !currentStatus,
        'lastUpdated': Timestamp.now(),
      };

      if (!currentStatus) {
        // ✅ MARKING AS COMPLETE
        updateData['completedAt'] = Timestamp.now();
        updateData['completedToday'] = todayDate;

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'lifetimeCompletedTasks': FieldValue.increment(1)});
        }

        // ✅ Save to history if recurring (using data fetched BEFORE update)
        if (isRecurringTask && taskData != null) {
          await _saveCompletionToHistory(docID, taskData);
        }
      } else {
        // ✅ MARKING AS INCOMPLETE
        updateData['completedAt'] = FieldValue.delete();
        updateData['completedToday'] = null;

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final currentCount = userDoc.data()?['lifetimeCompletedTasks'] ?? 0;

          if (currentCount > 0) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'lifetimeCompletedTasks': FieldValue.increment(-1)});
          }
        }

        // ✅ NEW: Delete today's completion from history if recurring
        if (isRecurringTask) {
          await _deleteCompletionFromHistory(docID, todayDate);
        }
      }

      await _userNotes.doc(docID).update(updateData);
      debugPrint(
        '✅ Task $docID toggled. Recurring: $isRecurringTask, Complete: ${!currentStatus}',
      );
    } catch (e) {
      debugPrint('Error toggling completion in Firebase: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Delete a specific date's completion from history
  Future<void> _deleteCompletionFromHistory(
    String taskId,
    String dateKey,
  ) async {
    try {
      await _getTaskHistoryRef(taskId).doc(dateKey).delete();
      debugPrint('🗑️ Deleted completion from history: $taskId on $dateKey');
    } catch (e) {
      debugPrint('❌ Error deleting from history: $e');
    }
  }

  /// ✅ Reset recurring tasks for the new day
  Future<void> resetRecurringTasks() async {
    try {
      final now = DateTime.now();
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final snapshot = await _userNotes
          .where('status', isEqualTo: 'accepted')
          .where('isRecurring', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final completedToday = data['completedToday'] as String?;

        // Only reset if not completed today
        if (completedToday != todayDate) {
          batch.update(doc.reference, {
            'isCompleted': false,
            'completedToday': null,
            'lastUpdated': Timestamp.now(),
            'elapsedSeconds': 0,
            'isRunning': false,
            'startTime': FieldValue.delete(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Recurring tasks reset successfully');
    } catch (e) {
      debugPrint('Error resetting recurring tasks: $e');
    }
  }

  /// ✅ Check if we need to reset recurring tasks
  Future<bool> shouldResetRecurringTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final lastResetTimestamp =
          userDoc.data()?['lastRecurringReset'] as Timestamp?;

      if (lastResetTimestamp == null) return true;

      final lastReset = lastResetTimestamp.toDate();
      final now = DateTime.now();

      return lastReset.year != now.year ||
          lastReset.month != now.month ||
          lastReset.day != now.day;
    } catch (e) {
      debugPrint('Error checking recurring reset: $e');
      return false;
    }
  }

  /// ✅ Mark that we've reset recurring tasks today
  Future<void> markRecurringTasksReset() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastRecurringReset': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking recurring reset: $e');
    }
  }

  /// Starts the timer on a task
  Future<void> startTimer(String docId) async {
    try {
      final docRef = _userNotes.doc(docId);
      await docRef.update({
        'isRunning': true,
        'startTime': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error starting timer in Firebase: $e');
      rethrow;
    }
  }

  /// Pauses the timer on a task
  Future<void> pauseTimer(String docId, int elapsedSeconds) async {
    try {
      final docRef = _userNotes.doc(docId);
      await docRef.update({
        'isRunning': false,
        'startTime': FieldValue.delete(),
        'elapsedSeconds': elapsedSeconds,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error pausing timer in Firebase: $e');
      rethrow;
    }
  }

  /// Stops and resets the timer for a task
  Future<void> stopTimer(String docId) async {
    try {
      final docRef = _userNotes.doc(docId);
      await docRef.update({
        'isRunning': false,
        'startTime': FieldValue.delete(),
        'elapsedSeconds': 0,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error stopping timer in Firebase: $e');
      rethrow;
    }
  }

  /// Get user statistics
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
          final completedAt = data['completedAt'] as Timestamp?;
          if (completedAt != null) {
            final dateKey = _formatDate(completedAt.toDate());
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
      debugPrint('Error getting user statistics: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHours': 0,
        'currentStreak': 0,
        'completionsByDate': {},
      };
    }
  }

  /// Get heatmap data stream
  Stream<Map<String, int>> getHeatmapData() {
    return _userNotes
        .where('status', isEqualTo: 'accepted')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final Map<String, int> heatmap = {};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final completedAt = data['completedAt'] as Timestamp?;
            if (completedAt != null) {
              final d = completedAt.toDate();
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
      debugPrint('Error getting username: $e');
      return 'User';
    }
  }

  Map<String, dynamic> getUserTier(int completedTasks) {
    final List<Map<String, dynamic>> tiers = [
      {
        "id": 1,
        "name": "The Starter",
        "completedTasks": 0,
        "icon": "circle",
        "gradient": [const Color(0xFF64748B), const Color(0xFF334155)],
        "glow": const Color(0xFF94A3B8),
      },
      {
        "id": 2,
        "name": "The Awakened",
        "completedTasks": 10,
        "icon": "sunrise",
        "gradient": [const Color(0xFF667eea), const Color(0xFF764ba2)],
        "glow": const Color(0xFFf093fb),
      },
      {
        "id": 3,
        "name": "The Seeker",
        "completedTasks": 50,
        "icon": "target",
        "gradient": [const Color(0xFFCD7F32), const Color(0xFFB87333)],
        "glow": const Color(0xFFD4A574),
      },
      {
        "id": 4,
        "name": "The Novice",
        "completedTasks": 100,
        "icon": "book",
        "gradient": [const Color(0xFF10B981), const Color(0xFF059669)],
        "glow": const Color(0xFF34D399),
      },
      {
        "id": 5,
        "name": "The Apprentice",
        "completedTasks": 250,
        "icon": "hammer",
        "gradient": [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        "glow": const Color(0xFFFBBF24),
      },
      {
        "id": 6,
        "name": "The Adept",
        "completedTasks": 500,
        "icon": "zap",
        "gradient": [const Color(0xFFF97316), const Color(0xFFEA580C)],
        "glow": const Color(0xFFFB923C),
      },
      {
        "id": 7,
        "name": "The Disciplined",
        "completedTasks": 1000,
        "icon": "shield",
        "gradient": [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
        "glow": const Color(0xFFA78BFA),
      },
      {
        "id": 8,
        "name": "The Specialist",
        "completedTasks": 2500,
        "icon": "award",
        "gradient": [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        "glow": const Color(0xFFF472B6),
      },
      {
        "id": 9,
        "name": "The Expert",
        "completedTasks": 5000,
        "icon": "crown",
        "gradient": [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        "glow": const Color(0xFF818CF8),
      },
      {
        "id": 10,
        "name": "The Vanguard",
        "completedTasks": 10000,
        "icon": "flame",
        "gradient": [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        "glow": const Color(0xFFF87171),
      },
      {
        "id": 11,
        "name": "The Sentinel",
        "completedTasks": 15000,
        "icon": "eye",
        "gradient": [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
        "glow": const Color(0xFF22D3EE),
      },
      {
        "id": 12,
        "name": "The Virtuoso",
        "completedTasks": 25000,
        "icon": "music",
        "gradient": [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        "glow": const Color(0xFF2DD4BF),
      },
      {
        "id": 13,
        "name": "The Master",
        "completedTasks": 40000,
        "icon": "trophy",
        "gradient": [const Color(0xFFEAB308), const Color(0xFFCA8A04)],
        "glow": const Color(0xFFFACC15),
      },
      {
        "id": 14,
        "name": "The Grandmaster",
        "completedTasks": 60000,
        "icon": "gem",
        "gradient": [const Color(0xFF22C55E), const Color(0xFF16A34A)],
        "glow": const Color(0xFF4ADE80),
      },
      {
        "id": 15,
        "name": "The Titan",
        "completedTasks": 75000,
        "icon": "mountain",
        "gradient": [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
        "glow": const Color(0xFF60A5FA),
      },
      {
        "id": 16,
        "name": "The Luminary",
        "completedTasks": 90000,
        "icon": "sun",
        "gradient": [
          const Color(0xFFFFD700),
          const Color(0xFFB8860B),
          const Color(0xFF8B6914),
        ],
        "glow": const Color(0xFFDAA520),
        "animated": true,
      },
      {
        "id": 17,
        "name": "The Ascended",
        "completedTasks": 100000,
        "icon": "infinity",
        "gradient": [
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
          const Color(0xFF0F3460),
          const Color(0xFF533483),
        ],
        "glow": const Color(0xFF4A5568),
        "animated": true,
        "prismatic": true,
      },
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
      'circle': LucideIcons.circle,
      'sunrise': LucideIcons.sunrise,
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
      'star': LucideIcons.star,
    };

    return iconMap[iconName] ?? LucideIcons.star;
  }

  /// Get statistics for a specific user
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
          final completedAt = data['completedAt'] as Timestamp?;
          if (completedAt != null) {
            final dateKey = _formatDate(completedAt.toDate());
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
      debugPrint('Error getting user statistics: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'totalHours': 0,
        'currentStreak': 0,
        'completionsByDate': {},
      };
    }
  }

  /// Get heatmap data for a specific user
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
            final completedAt = data['completedAt'] as Timestamp?;
            if (completedAt != null) {
              final d = completedAt.toDate();
              final key = _formatDate(d);
              heatmap[key] = (heatmap[key] ?? 0) + 1;
            }
          }
          return heatmap;
        });
  }

  /// ✅ FIXED: Get completion history for a specific recurring task
  Future<Map<String, int>> getRecurringTaskHistory(String taskId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        return {};
      }

      final historySnapshot = await FirebaseFirestore.instance
          .collection('recurringHistory')
          .doc(user.uid)
          .collection(taskId)
          .doc('completions')
          .collection('dates')
          .get();

      final Map<String, int> history = {};
      for (var doc in historySnapshot.docs) {
        // doc.id is the date string (e.g., "2025-10-23")
        history[doc.id] = 1; // Each date counts as 1 completion
      }

      debugPrint('📊 Loaded history for task $taskId: ${history.length} days');
      debugPrint('📅 Dates: ${history.keys.join(", ")}');
      return history;
    } catch (e) {
      debugPrint('❌ Error fetching recurring task history: $e');
      return {};
    }
  }

  /// Get total completion count for a recurring task
  Future<int> getRecurringTaskCompletionCount(String taskId) async {
    try {
      final history = await getRecurringTaskHistory(taskId);
      return history.length;
    } catch (e) {
      debugPrint('Error getting completion count: $e');
      return 0;
    }
  }

  /// ✅ Get completion history for a FRIEND's specific recurring task
  Future<Map<String, int>> getRecurringTaskHistoryForUser(
    String taskId,
    String userId,
  ) async {
    try {
      debugPrint('🔍 Fetching history for user: $userId, task: $taskId');

      final historySnapshot = await FirebaseFirestore.instance
          .collection('recurringHistory')
          .doc(userId) // ✅ Use the friend's user ID
          .collection(taskId)
          .doc('completions')
          .collection('dates')
          .get();

      final Map<String, int> history = {};
      for (var doc in historySnapshot.docs) {
        // doc.id is the date string (e.g., "2025-10-23")
        history[doc.id] = 1; // Each date counts as 1 completion
      }

      debugPrint(
        '📊 Loaded history for friend\'s task $taskId: ${history.length} days',
      );
      debugPrint('📅 Dates: ${history.keys.join(", ")}');
      return history;
    } catch (e) {
      debugPrint('❌ Error fetching friend recurring task history: $e');
      return {};
    }
  }

  /// Get total completion count for a FRIEND's recurring task
  Future<int> getRecurringTaskCompletionCountForUser(
    String taskId,
    String userId,
  ) async {
    try {
      final history = await getRecurringTaskHistoryForUser(taskId, userId);
      return history.length;
    } catch (e) {
      debugPrint('Error getting friend completion count: $e');
      return 0;
    }
  }
}
