import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete messages older than 1 month
  Future<void> cleanupOldMessages() async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final cutoffTimestamp = Timestamp.fromDate(oneMonthAgo);

      // Get all chat rooms
      final chatRoomsSnapshot = await _firestore.collection('chat_rooms').get();

      int deletedMessages = 0;

      for (var chatRoom in chatRoomsSnapshot.docs) {
        // Get messages older than 1 month in this chat room
        final oldMessages = await chatRoom.reference
            .collection('messages')
            .where('timestamp', isLessThan: cutoffTimestamp)
            .get();

        // Delete each old message
        for (var message in oldMessages.docs) {
          await message.reference.delete();
          deletedMessages++;
        }
      }

      debugPrint('🗑️ Cleaned up $deletedMessages old messages');
    } catch (e) {
      debugPrint('❌ Error cleaning up old messages: $e');
    }
  }

  /// Delete completed tasks older than 3 months (including recurring history)
  Future<void> cleanupOldTasks(String userID) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final cutoffTimestamp = Timestamp.fromDate(threeMonthsAgo);

      // Get old completed tasks
      final oldTasks = await _firestore
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isLessThan: cutoffTimestamp)
          .get();

      int deletedTasks = 0;
      int deletedHistoryEntries = 0;

      // Delete each old task and its recurring history
      for (var task in oldTasks.docs) {
        final taskId = task.id;
        final taskData = task.data();
        final isRecurring = taskData['isRecurring'] == true;

        // If recurring, delete its history
        if (isRecurring) {
          final historyDeleted =
              await _cleanupRecurringHistoryForTask(userID, taskId);
          deletedHistoryEntries += historyDeleted;
        }

        // Delete the task itself
        await task.reference.delete();
        deletedTasks++;
      }

      debugPrint(
        '🗑️ Cleaned up $deletedTasks old tasks and $deletedHistoryEntries history entries for user $userID',
      );
    } catch (e) {
      debugPrint('❌ Error cleaning up old tasks: $e');
    }
  }

  /// ✅ NEW: Delete recurring task history older than 3 months
  Future<void> cleanupOldRecurringHistory(String userID) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final cutoffDate =
          '${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}';

      int deletedHistoryEntries = 0;

      // Get all tasks to check for recurring ones
      final tasksSnapshot = await _firestore
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isRecurring', isEqualTo: true)
          .get();

      for (var task in tasksSnapshot.docs) {
        final taskId = task.id;

        // Get old history entries for this task
        final historySnapshot = await _firestore
            .collection('recurringHistory')
            .doc(userID)
            .collection(taskId)
            .doc('completions')
            .collection('dates')
            .get();

        for (var dateDoc in historySnapshot.docs) {
          final dateString = dateDoc.id; // e.g., "2025-07-15"

          // Compare date strings
          if (dateString.compareTo(cutoffDate) < 0) {
            await dateDoc.reference.delete();
            deletedHistoryEntries++;
          }
        }
      }

      debugPrint(
        '🗑️ Cleaned up $deletedHistoryEntries old recurring history entries for user $userID',
      );
    } catch (e) {
      debugPrint('❌ Error cleaning up old recurring history: $e');
    }
  }

  /// ✅ Helper: Delete all recurring history for a specific task
  Future<int> _cleanupRecurringHistoryForTask(
    String userID,
    String taskId,
  ) async {
    try {
      int deletedCount = 0;

      final historySnapshot = await _firestore
          .collection('recurringHistory')
          .doc(userID)
          .collection(taskId)
          .doc('completions')
          .collection('dates')
          .get();

      for (var dateDoc in historySnapshot.docs) {
        await dateDoc.reference.delete();
        deletedCount++;
      }

      // Delete the completions document
      await _firestore
          .collection('recurringHistory')
          .doc(userID)
          .collection(taskId)
          .doc('completions')
          .delete();

      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error cleaning history for task $taskId: $e');
      return 0;
    }
  }

  /// Cleanup all old data for ALL users (use with caution - expensive operation)
  Future<void> cleanupAllUsersOldTasks() async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final cutoffTimestamp = Timestamp.fromDate(threeMonthsAgo);

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      int totalDeletedTasks = 0;
      int totalDeletedHistory = 0;

      for (var user in usersSnapshot.docs) {
        try {
          final oldTasks = await _firestore
              .collection('user_notes')
              .doc(user.id)
              .collection('notes')
              .where('isCompleted', isEqualTo: true)
              .where('completedAt', isLessThan: cutoffTimestamp)
              .get();

          for (var task in oldTasks.docs) {
            final taskId = task.id;
            final taskData = task.data();
            final isRecurring = taskData['isRecurring'] == true;

            // If recurring, delete its history
            if (isRecurring) {
              final historyDeleted =
                  await _cleanupRecurringHistoryForTask(user.id, taskId);
              totalDeletedHistory += historyDeleted;
            }

            await task.reference.delete();
            totalDeletedTasks++;
          }

          // Also clean up old recurring history for active tasks
          final historyDeleted = await _cleanupOldRecurringHistoryForUser(
            user.id,
            threeMonthsAgo,
          );
          totalDeletedHistory += historyDeleted;
        } catch (e) {
          debugPrint('❌ Error cleaning tasks for user ${user.id}: $e');
        }
      }

      debugPrint(
        '🗑️ Cleaned up $totalDeletedTasks old tasks and $totalDeletedHistory history entries across all users',
      );
    } catch (e) {
      debugPrint('❌ Error in cleanup all users: $e');
    }
  }

  /// ✅ Helper: Clean up old recurring history for a specific user
  Future<int> _cleanupOldRecurringHistoryForUser(
    String userID,
    DateTime cutoffDate,
  ) async {
    try {
      int deletedCount = 0;
      final cutoffDateString =
          '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      // Get all recurring tasks
      final recurringTasks = await _firestore
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isRecurring', isEqualTo: true)
          .get();

      for (var task in recurringTasks.docs) {
        final taskId = task.id;

        final historySnapshot = await _firestore
            .collection('recurringHistory')
            .doc(userID)
            .collection(taskId)
            .doc('completions')
            .collection('dates')
            .get();

        for (var dateDoc in historySnapshot.docs) {
          final dateString = dateDoc.id;

          if (dateString.compareTo(cutoffDateString) < 0) {
            await dateDoc.reference.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error cleaning recurring history for user $userID: $e');
      return 0;
    }
  }

  /// ✅ ENHANCED: Run all cleanup operations (messages + tasks + recurring history)
  Future<void> runFullCleanup(String userID) async {
    debugPrint('🧹 Starting full cleanup for user $userID...');

    await cleanupOldMessages();
    await cleanupOldTasks(userID);
    await cleanupOldRecurringHistory(userID);

    debugPrint('✅ Full cleanup completed');
  }

  /// ✅ NEW: Run cleanup for all users (Admin operation)
  Future<void> runFullCleanupAllUsers() async {
    debugPrint('🧹 Starting full cleanup for ALL USERS...');

    await cleanupOldMessages();
    await cleanupAllUsersOldTasks();

    debugPrint('✅ Full cleanup completed for all users');
  }

  /// ✅ NEW: Get cleanup statistics before running cleanup
  Future<Map<String, int>> getCleanupStats(String userID) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final cutoffTimestamp = Timestamp.fromDate(threeMonthsAgo);

      // Count old tasks
      final oldTasksSnapshot = await _firestore
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isLessThan: cutoffTimestamp)
          .get();

      int oldTasksCount = oldTasksSnapshot.docs.length;
      int oldHistoryCount = 0;

      // Count old recurring history entries
      final cutoffDateString =
          '${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}';

      final recurringTasks = await _firestore
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isRecurring', isEqualTo: true)
          .get();

      for (var task in recurringTasks.docs) {
        final historySnapshot = await _firestore
            .collection('recurringHistory')
            .doc(userID)
            .collection(task.id)
            .doc('completions')
            .collection('dates')
            .get();

        for (var dateDoc in historySnapshot.docs) {
          if (dateDoc.id.compareTo(cutoffDateString) < 0) {
            oldHistoryCount++;
          }
        }
      }

      return {
        'oldTasks': oldTasksCount,
        'oldHistory': oldHistoryCount,
        'total': oldTasksCount + oldHistoryCount,
      };
    } catch (e) {
      debugPrint('❌ Error getting cleanup stats: $e');
      return {'oldTasks': 0, 'oldHistory': 0, 'total': 0};
    }
  }
}
