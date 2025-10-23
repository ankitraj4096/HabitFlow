import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyCompletedTasksPage extends StatelessWidget {
  final DateTime selectedDate;
  final String? viewingUserID;
  final String? viewingUsername;

  const DailyCompletedTasksPage({
    super.key,
    required this.selectedDate,
    this.viewingUserID,
    this.viewingUsername,
  });

  bool get isOwnProfile => viewingUserID == null;

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
              _buildHeader(context, tierProvider),
              Expanded(child: _buildTasksList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TierThemeProvider tierProvider) {
    final dateStr =
        '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';

    return Container(
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
            color: tierProvider.glowColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnProfile
                            ? 'Your Completed Tasks'
                            : '$viewingUsername\'s Tasks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    final userID =
        isOwnProfile ? FirebaseAuth.instance.currentUser?.uid : viewingUserID;

    if (userID == null) {
      return _buildEmptyState('Unable to load tasks', context);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllCompletedTasks(userID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Error loading tasks: ${snapshot.error}');
          return _buildEmptyState('Error loading tasks', context);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          final tierProvider = context.watch<TierThemeProvider>();
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(tierProvider.primaryColor),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];

        if (allTasks.isEmpty) {
          return _buildEmptyState('No tasks completed on this day', context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allTasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(allTasks[index]);
          },
        );
      },
    );
  }

  // ✅ FIXED: Fetch BOTH regular tasks AND recurring tasks
  Future<List<Map<String, dynamic>>> _fetchAllCompletedTasks(
      String userID) async {
    try {
      final dateKey =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final List<Map<String, dynamic>> allTasks = [];

      // 1️⃣ Fetch ALL notes (both recurring and non-recurring)
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('status', isEqualTo: 'accepted')
          .get();

      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, 23, 59, 59);

      for (var doc in notesSnapshot.docs) {
        final data = doc.data();
        final isRecurring = data['isRecurring'] == true;
        final taskId = doc.id;

        if (isRecurring) {
          // ✅ Check if this recurring task was completed on the selected date
          final dateDoc = await FirebaseFirestore.instance
              .collection('recurringHistory')
              .doc(userID)
              .collection(taskId)
              .doc('completions')
              .collection('dates')
              .doc(dateKey)
              .get();

          if (dateDoc.exists) {
            final historyData = dateDoc.data()!;
            allTasks.add({
              'taskName': historyData['taskName'] ?? data['taskName'],
              'completedAt': historyData['completedAt'],
              'hasTimer': data['hasTimer'] ?? false,
              'elapsedSeconds': historyData['duration'] ?? 0,
              'assignedByUsername': data['assignedByUsername'],
              'isRecurringTask': true,
            });
          }
        } else {
          // ✅ Regular task: check if completed on selected date
          final completedAt = data['completedAt'] as Timestamp?;
          final isCompleted = data['isCompleted'] == true;

          if (isCompleted && completedAt != null) {
            final completedDate = completedAt.toDate();
            if (completedDate.isAfter(startOfDay) &&
                completedDate.isBefore(endOfDay)) {
              allTasks.add({
                ...data,
                'isRecurringTask': false,
              });
            }
          }
        }
      }

      debugPrint('✅ Loaded ${allTasks.length} tasks for $dateKey');
      return allTasks;
    } catch (e) {
      debugPrint('❌ Error fetching all completed tasks: $e');
      return [];
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> taskData) {
    final taskName = taskData['taskName'] ?? 'Unnamed Task';
    final completedAt = taskData['completedAt'] as Timestamp?;
    final hasTimer = taskData['hasTimer'] ?? false;
    final elapsedSeconds = taskData['elapsedSeconds'] ?? 0;
    final assignedBy = taskData['assignedByUsername'];
    final isRecurring = taskData['isRecurringTask'] == true;

    String timeStr = 'Unknown time';
    if (completedAt != null) {
      final completedDate = completedAt.toDate();
      timeStr =
          '${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    taskName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Additional Info Row
            if (assignedBy != null || hasTimer || isRecurring) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // ✅ Show recurring badge
                  if (isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Daily',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (assignedBy != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'By: $assignedBy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasTimer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(elapsedSeconds),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tierProvider.gradientColors
                    .map((c) => c.withValues(alpha: 0.2))
                    .toList(),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: tierProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some tasks to see them here!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
