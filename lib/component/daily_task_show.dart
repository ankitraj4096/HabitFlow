import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyCompletedTasksPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? viewingUserID;
  final String? viewingUsername;

  const DailyCompletedTasksPage({
    super.key,
    required this.selectedDate,
    this.viewingUserID,
    this.viewingUsername,
  });

  @override
  State<DailyCompletedTasksPage> createState() =>
      _DailyCompletedTasksPageState();
}

class _DailyCompletedTasksPageState extends State<DailyCompletedTasksPage> {
  final FireStoreService _firestoreService = FireStoreService();

  // Friend's tier colors
  List<Color> friendGradientColors = [
    const Color(0xFF7C4DFF),
    const Color(0xFF448AFF),
  ];
  Color friendGlowColor = const Color(0xFF7C4DFF);
  Color friendPrimaryColor = const Color(0xFF7C4DFF);
  bool isLoadingFriendTier = true;

  bool get isOwnProfile => widget.viewingUserID == null;

  @override
  void initState() {
    super.initState();
    if (!isOwnProfile) {
      _loadFriendTierColors();
    }
  }

  Future<void> _loadFriendTierColors() async {
    try {
      // Fetch friend's lifetime completed tasks
      final friendUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.viewingUserID!)
          .get();

      final friendLifetimeCount =
          friendUserDoc.data()?['lifetimeCompletedTasks'] ?? 0;

      // Get friend's tier
      final tier = _firestoreService.getUserTier(friendLifetimeCount);

      if (mounted) {
        setState(() {
          friendGlowColor = tier['glow'] as Color? ?? const Color(0xFF7C4DFF);
          friendGradientColors = (tier['gradient'] as List<dynamic>?)
                  ?.map((e) => e as Color)
                  .toList() ??
              [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
          friendPrimaryColor = friendGlowColor;
          isLoadingFriendTier = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading friend tier colors: $e');
      if (mounted) {
        setState(() => isLoadingFriendTier = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    // Decide which colors to use
    final displayGradient =
        isOwnProfile ? tierProvider.gradientColors : friendGradientColors;
    final displayGlowColor =
        isOwnProfile ? tierProvider.glowColor : friendGlowColor;
    final displayPrimaryColor =
        isOwnProfile ? tierProvider.primaryColor : friendPrimaryColor;

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
              _buildHeader(
                context,
                displayGradient,
                displayGlowColor,
              ),
              Expanded(
                child: _buildTasksList(
                  context,
                  displayPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Color> gradientColors,
    Color glowColor,
  ) {
    final dateStr =
        '${widget.selectedDate.day} ${_getMonthName(widget.selectedDate.month)} ${widget.selectedDate.year}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
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
                            : '${widget.viewingUsername}\'s Tasks',
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

  Widget _buildTasksList(BuildContext context, Color primaryColor) {
    final userID = isOwnProfile
        ? FirebaseAuth.instance.currentUser?.uid
        : widget.viewingUserID;

    if (userID == null) {
      return _buildEmptyState('Unable to load tasks', primaryColor);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllCompletedTasks(userID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('❌ Error loading tasks: ${snapshot.error}');
          return _buildEmptyState('Error loading tasks', primaryColor);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];

        if (allTasks.isEmpty) {
          return _buildEmptyState('No tasks completed on this day', primaryColor);
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

  Future<List<Map<String, dynamic>>> _fetchAllCompletedTasks(
      String userID) async {
    try {
      final dateKey =
          '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

      final List<Map<String, dynamic>> allTasks = [];

      final notesSnapshot = await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('status', isEqualTo: 'accepted')
          .get();

      final startOfDay = DateTime(
          widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
      final endOfDay = DateTime(widget.selectedDate.year, widget.selectedDate.month,
          widget.selectedDate.day, 23, 59, 59);

      for (var doc in notesSnapshot.docs) {
        final data = doc.data();
        final isRecurring = data['isRecurring'] == true;
        final taskId = doc.id;

        if (isRecurring) {
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
            if (assignedBy != null || hasTimer || isRecurring) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
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

  Widget _buildEmptyState(String message, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: primaryColor,
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
