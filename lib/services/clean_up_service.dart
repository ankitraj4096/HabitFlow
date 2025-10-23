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
      debugPrint('Error cleaning up old messages: $e');
    }
  }

  /// Delete completed tasks older than 3 months
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

      // Delete each old task
      for (var task in oldTasks.docs) {
        await task.reference.delete();
        deletedTasks++;
      }

      debugPrint('🗑️ Cleaned up $deletedTasks old tasks for user $userID');
    } catch (e) {
      debugPrint('Error cleaning up old tasks: $e');
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
            await task.reference.delete();
            totalDeletedTasks++;
          }
        } catch (e) {
          debugPrint('Error cleaning tasks for user ${user.id}: $e');
        }
      }

      debugPrint('🗑️ Cleaned up $totalDeletedTasks old tasks across all users');
    } catch (e) {
      debugPrint('Error in cleanup all users: $e');
    }
  }

  /// Run all cleanup operations (messages + tasks for current user)
  Future<void> runFullCleanup(String userID) async {
    debugPrint('🧹 Starting full cleanup...');
    await cleanupOldMessages();
    await cleanupOldTasks(userID);
    debugPrint('✅ Cleanup completed');
  }
}
