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
        'assignedByUserID': null,
        'assignedByUsername': null,
        'status': 'accepted',
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

  /// Assign a task to a friend
  Future<String?> assignTaskToFriend({
    required String friendUserID,
    required String taskName,
    int? durationMins,
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

  /// Get count of pending task requests
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

  /// Get stream of pending task requests
  Stream<QuerySnapshot> getPendingTaskRequestsStream() {
    try {
      return _userNotes.where('status', isEqualTo: 'pending').snapshots();
    } catch (e) {
      print('Error getting pending task requests: $e');
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
      print('Error accepting task request: $e');
      rethrow;
    }
  }

  /// Decline a task request
  Future<void> declineTaskRequest(String docID) async {
    try {
      await _userNotes.doc(docID).delete();
    } catch (e) {
      print('Error declining task request: $e');
      rethrow;
    }
  }

  /// Get tasks stream
  Stream<QuerySnapshot> getTasksStream() {
    try {
      return _userNotes.orderBy('timestamp', descending: false).snapshots();
    } catch (e) {
      print('Error getting tasks stream: $e');
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
  /// Toggle task completion status - UPDATE to increment lifetime counter
  Future<void> toggleCompletion(String docID, bool currentStatus) async {
    try {
      final Map<String, dynamic> updateData = {
        'isCompleted': !currentStatus,
        'lastUpdated': Timestamp.now(),
      };

      if (!currentStatus) {
        // Task is being completed
        updateData['completedAt'] = Timestamp.now();

        // ✅ NEW: Increment lifetime completed tasks
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'lifetimeCompletedTasks': FieldValue.increment(1)});
        }
      } else {
        // Task is being uncompleted
        updateData['completedAt'] = FieldValue.delete();

        // ✅ NEW: Decrement lifetime completed tasks
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
      }

      await _userNotes.doc(docID).update(updateData);
    } catch (e) {
      print('Error toggling completion in Firebase: $e');
      rethrow;
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
      print('Error starting timer in Firebase: $e');
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
      print('Error pausing timer in Firebase: $e');
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
      print('Error stopping timer in Firebase: $e');
      rethrow;
    }
  }

  /// Get user statistics - FIXED to use completedAt
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
          // ✅ FIXED: Changed from 'timestamp' to 'completedAt'
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

  /// Get heatmap data stream - FIXED to use completedAt
  Stream<Map<String, int>> getHeatmapData() {
    return _userNotes
        .where('status', isEqualTo: 'accepted')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final Map<String, int> heatmap = {};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            // ✅ FIXED: Changed from 'timestamp' to 'completedAt'
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
      print('Error getting username: $e');
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
        "gradient": [
          const Color(0xFF64748B), // Slate blue
          const Color(0xFF334155), // Deep slate
        ],
        "glow": const Color(0xFF94A3B8),
      },
      {
        "id": 2,
        "name": "The Awakened",
        "completedTasks": 10,
        "icon": "sunrise",
        "gradient": [
          const Color(0xFF667eea), // Purple blue (from login page)
          const Color(0xFF764ba2), // Deep purple (from login page)
        ],
        "glow": const Color(0xFFf093fb), // Pink glow
      },
      {
        "id": 3,
        "name": "The Seeker",
        "completedTasks": 50,
        "icon": "target",
        "gradient": [
          const Color(0xFFCD7F32), // Bronze
          const Color(0xFFB87333), // Copper
        ],
        "glow": const Color(0xFFD4A574),
      },
      {
        "id": 4,
        "name": "The Novice",
        "completedTasks": 100,
        "icon": "book",
        "gradient": [
          const Color(0xFF10B981), // Emerald green
          const Color(0xFF059669), // Deep emerald
        ],
        "glow": const Color(0xFF34D399),
      },
      {
        "id": 5,
        "name": "The Apprentice",
        "completedTasks": 250,
        "icon": "hammer",
        "gradient": [
          const Color(0xFFF59E0B), // Rich amber
          const Color(0xFFD97706), // Deep amber
        ],
        "glow": const Color(0xFFFBBF24),
      },
      {
        "id": 6,
        "name": "The Adept",
        "completedTasks": 500,
        "icon": "zap",
        "gradient": [
          const Color(0xFFF97316), // Vibrant orange
          const Color(0xFFEA580C), // Deep orange
        ],
        "glow": const Color(0xFFFB923C),
      },
      {
        "id": 7,
        "name": "The Disciplined",
        "completedTasks": 1000,
        "icon": "shield",
        "gradient": [
          const Color(0xFF8B5CF6), // Rich purple
          const Color(0xFF6D28D9), // Deep purple
        ],
        "glow": const Color(0xFFA78BFA),
      },
      {
        "id": 8,
        "name": "The Specialist",
        "completedTasks": 2500,
        "icon": "award",
        "gradient": [
          const Color(0xFFEC4899), // Hot pink
          const Color(0xFFDB2777), // Deep pink
        ],
        "glow": const Color(0xFFF472B6),
      },
      {
        "id": 9,
        "name": "The Expert",
        "completedTasks": 5000,
        "icon": "crown",
        "gradient": [
          const Color(0xFF6366F1), // Indigo
          const Color(0xFF4F46E5), // Deep indigo
        ],
        "glow": const Color(0xFF818CF8),
      },
      {
        "id": 10,
        "name": "The Vanguard",
        "completedTasks": 10000,
        "icon": "flame",
        "gradient": [
          const Color(0xFFEF4444), // Bold red
          const Color(0xFFDC2626), // Deep red
        ],
        "glow": const Color(0xFFF87171),
      },
      {
        "id": 11,
        "name": "The Sentinel",
        "completedTasks": 15000,
        "icon": "eye",
        "gradient": [
          const Color(0xFF06B6D4), // Cyan
          const Color(0xFF0891B2), // Deep cyan
        ],
        "glow": const Color(0xFF22D3EE),
      },
      {
        "id": 12,
        "name": "The Virtuoso",
        "completedTasks": 25000,
        "icon": "music",
        "gradient": [
          const Color(0xFF14B8A6), // Teal
          const Color(0xFF0D9488), // Deep teal
        ],
        "glow": const Color(0xFF2DD4BF),
      },
      {
        "id": 13,
        "name": "The Master",
        "completedTasks": 40000,
        "icon": "trophy",
        "gradient": [
          const Color(0xFFEAB308), // Gold
          const Color(0xFFCA8A04), // Deep gold
        ],
        "glow": const Color(0xFFFACC15),
      },
      {
        "id": 14,
        "name": "The Grandmaster",
        "completedTasks": 60000,
        "icon": "gem",
        "gradient": [
          const Color(0xFF22C55E), // Lime green
          const Color(0xFF16A34A), // Deep lime
        ],
        "glow": const Color(0xFF4ADE80),
      },
      {
        "id": 15,
        "name": "The Titan",
        "completedTasks": 75000,
        "icon": "mountain",
        "gradient": [
          const Color(0xFF3B82F6), // Vibrant blue
          const Color(0xFF1E40AF), // Deep blue
        ],
        "glow": const Color(0xFF60A5FA),
      },
      {
        "id": 16,
        "name": "The Luminary",
        "completedTasks": 90000,
        "icon": "sun",
        "gradient": [
          const Color(0xFFFFD700), // Pure gold
          const Color(0xFFB8860B), // Dark goldenrod
          const Color(0xFF8B6914), // Deep bronze gold
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
          const Color(0xFF1A1A2E), // Deep navy
          const Color(0xFF16213E), // Midnight blue
          const Color(0xFF0F3460), // Dark blue
          const Color(0xFF533483), // Deep purple
        ],
        "glow": const Color(0xFF4A5568),
        "animated": true,
        "prismatic": true,
      },
    ];

    // Always default to Tier 1 (The Starter) for users with 0-9 tasks
    Map<String, dynamic> currentTier = tiers[0];

    // Find the highest tier the user qualifies for
    for (final tier in tiers) {
      if (completedTasks >= tier['completedTasks']) {
        currentTier = tier;
      } else {
        // Once we find a tier we don't qualify for, stop checking
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

  /// Get statistics for a specific user - FIXED to use completedAt
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
          // ✅ FIXED: Changed from 'timestamp' to 'completedAt'
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

  /// Get heatmap data for a specific user - FIXED to use completedAt
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
            // ✅ FIXED: Changed from 'timestamp' to 'completedAt'
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
}
