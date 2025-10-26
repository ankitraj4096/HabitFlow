import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/component/custom_toast.dart';
import 'package:demo/component/recurring_history_page.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FriendTasksManagerPage extends StatefulWidget {
  final String friendUserID;
  final String friendUsername;

  const FriendTasksManagerPage({
    super.key,
    required this.friendUserID,
    required this.friendUsername,
  });

  @override
  State<FriendTasksManagerPage> createState() => _FriendTasksManagerPageState();
}

class _FriendTasksManagerPageState extends State<FriendTasksManagerPage>
    with SingleTickerProviderStateMixin {
  final FireStoreService _firestoreService = FireStoreService();
  late TabController _tabController;

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _timerController = TextEditingController();

  // Friend's tier colors
  List<Color> friendGradientColors = [
    const Color(0xFF7C4DFF),
    const Color(0xFF448AFF),
  ];
  Color friendPrimaryColor = const Color(0xFF7C4DFF);
  Color friendGlowColor = const Color(0xFF7C4DFF);
  bool isLoadingFriendTier = true;
  bool isRecurringTask = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendTier();
  }

  Future<void> _loadFriendTier() async {
    try {
      final stats = await _firestoreService.getUserStatisticsForUser(
        widget.friendUserID,
      );
      final tier = _firestoreService.getUserTier(stats['completedTasks']);

      setState(() {
        friendGlowColor = tier['glow'] as Color? ?? const Color(0xFF7C4DFF);
        friendGradientColors =
            (tier['gradient'] as List<dynamic>?)
                ?.map((e) => e as Color)
                .toList() ??
            [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
        friendPrimaryColor = friendGradientColors[0];
        isLoadingFriendTier = false;
      });
    } catch (e) {
      debugPrint('Error loading friend tier: $e');
      setState(() => isLoadingFriendTier = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  // Group tasks by date
  Map<String, List<QueryDocumentSnapshot>> groupTasksByDate(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final dateOnly = DateTime(date.year, date.month, date.day);

      String dateKey;
      if (dateOnly == today) {
        dateKey = 'Today';
      } else if (dateOnly == yesterday) {
        dateKey = 'Yesterday';
      } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
        dateKey = DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
      } else {
        dateKey = DateFormat('MMM dd, yyyy').format(date); // Jan 01, 2025
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(doc); // ✅ Add the doc itself, not just data
    }

    return grouped;
  }

  void _showAssignTaskDialog() {
    setState(() {
      isRecurringTask = false; // Reset toggle
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: friendGlowColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: friendGradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: friendGlowColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: friendPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'To ${widget.friendUsername}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      labelText: 'Task Name',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      hintText: 'Enter your task...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.edit_rounded,
                        color: friendPrimaryColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: friendPrimaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: TextField(
                    controller: _timerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Timer (minutes)',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      hintText: 'Optional, e.g., 25',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.timer_outlined,
                        color: friendPrimaryColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: friendPrimaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // ✅ Recurring task toggle
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isRecurringTask
                            ? friendPrimaryColor.withValues(alpha: 0.08)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRecurringTask
                              ? friendPrimaryColor.withValues(alpha: 0.3)
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isRecurringTask
                                    ? friendPrimaryColor.withValues(alpha: 0.3)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Icon(
                              Icons.repeat_rounded,
                              color: isRecurringTask
                                  ? friendPrimaryColor
                                  : Colors.grey[600],
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Daily Recurring',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isRecurringTask
                                    ? friendPrimaryColor
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          Switch(
                            value: isRecurringTask,
                            onChanged: (value) {
                              setDialogState(() {
                                setState(() {
                                  isRecurringTask = value;
                                });
                              });
                            },
                            activeColor: friendPrimaryColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _taskController.clear();
                            _timerController.clear();
                            setState(() {
                              isRecurringTask = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: friendGradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: friendGlowColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_taskController.text.isEmpty) {
                              CustomToast.warning(
                                context,
                                'Please enter a task name',
                              );
                              return;
                            }

                            final timerMins = _timerController.text.isNotEmpty
                                ? int.tryParse(_timerController.text)
                                : null;

                            try {
                              await _firestoreService.assignTaskToFriend(
                                friendUserID: widget.friendUserID,
                                taskName: _taskController.text,
                                durationMins: timerMins,
                                isRecurring: isRecurringTask,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                _taskController.clear();
                                _timerController.clear();
                                setState(() {
                                  isRecurringTask = false;
                                });
                                CustomToast.success(
                                  context,
                                  'Task assigned to ${widget.friendUsername}! ✅',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomToast.error(
                                  context,
                                  'Failed to assign task: $e',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingFriendTier) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(friendPrimaryColor),
          ),
        ),
      );
    }

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
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignTaskDialog,
        backgroundColor: friendPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Assign Task'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: friendGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: friendGlowColor.withValues(alpha: 0.3),
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
                        '${widget.friendUsername}\'s Tasks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'View and assign tasks',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: friendGradientColors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: friendGlowColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_rounded, size: 18),
                SizedBox(width: 6),
                Text('Overview'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 6),
                Text('My Tasks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [_buildAllTasksTab(), _buildTasksByMeTab()],
    );
  }

  Widget _buildAllTasksTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_notes')
          .doc(widget.friendUserID)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading tasks: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final allDocs =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];
              return status == 'accepted' || status == null;
            }).toList() ??
            [];

        if (allDocs.isEmpty) {
          return _buildEmptyState('No tasks yet', Icons.task_alt);
        }

        // ✅ NEW: Sort tasks - incomplete first, then completed
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aCompleted = aData['isCompleted'] ?? false;
          final bCompleted = bData['isCompleted'] ?? false;

          // If completion status is different, incomplete comes first
          if (aCompleted != bCompleted) {
            return aCompleted
                ? 1
                : -1; // false (incomplete) comes before true (completed)
          }

          // If both have same completion status, sort by timestamp (newest first)
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;

          if (aTimestamp == null || bTimestamp == null) return 0;
          return bTimestamp.compareTo(aTimestamp); // Newest first
        });

        // Group tasks by date
        final groupedTasks = groupTasksByDate(allDocs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedTasks.length,
          itemBuilder: (context, index) {
            final dateKey = groupedTasks.keys.elementAt(index);
            final tasks = groupedTasks[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(dateKey, tasks.length),
                const SizedBox(height: 8),
                ...tasks.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildTaskCard({...data, 'firebaseId': doc.id});
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTasksByMeTab() {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_notes')
          .doc(widget.friendUserID)
          .collection('notes')
          .where('assignedByUserID', isEqualTo: currentUserID)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(
            'Error loading your assigned tasks: ${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'You haven\'t assigned any tasks yet',
            Icons.person_add_alt,
          );
        }

        // ✅ NEW: Get docs and sort them
        final allDocs = snapshot.data!.docs.toList();

        // Sort tasks - incomplete first, then completed
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aCompleted = aData['isCompleted'] ?? false;
          final bCompleted = bData['isCompleted'] ?? false;

          // If completion status is different, incomplete comes first
          if (aCompleted != bCompleted) {
            return aCompleted ? 1 : -1;
          }

          // If both have same completion status, sort by timestamp (newest first)
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;

          if (aTimestamp == null || bTimestamp == null) return 0;
          return bTimestamp.compareTo(aTimestamp);
        });

        final groupedTasks = groupTasksByDate(allDocs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedTasks.length,
          itemBuilder: (context, index) {
            final dateKey = groupedTasks.keys.elementAt(index);
            final tasks = groupedTasks[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(dateKey, tasks.length),
                const SizedBox(height: 8),
                ...tasks.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildTaskCard({
                    ...data,
                    'firebaseId': doc.id,
                  }, highlightMyTask: true);
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(String dateLabel, int taskCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: friendGradientColors
              .map((c) => c.withValues(alpha: 0.1))
              .toList(),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: friendPrimaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: friendPrimaryColor),
          const SizedBox(width: 8),
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: friendPrimaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: friendPrimaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$taskCount task${taskCount != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: friendPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    Map<String, dynamic> data, {
    bool highlightMyTask = false,
  }) {
    final taskName = data['taskName'] ?? 'Unnamed Task';
    final isCompleted = data['isCompleted'] ?? false;
    final assignedBy = data['assignedByUsername'];
    final status = data['status'] ?? 'accepted';
    final hasTimer = data['hasTimer'] ?? false;
    final totalDuration = data['totalDuration'];
    final elapsedSeconds = data['elapsedSeconds'] ?? 0;
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final isMyTask = data['assignedByUserID'] == currentUserID;

    double? timerProgress;
    if (hasTimer && totalDuration != null && totalDuration > 0) {
      timerProgress = (elapsedSeconds / totalDuration).clamp(0.0, 1.0);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (data['isRecurring'] == true && data['firebaseId'] != null) {
          debugPrint('✅ Navigating to history page...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecurringTaskHistoryPage(
                taskId: data['firebaseId'],
                taskName: taskName,
                friendUserID: widget.friendUserID,
                friendUsername: widget.friendUsername,
              ),
            ),
          );
        } else {
          debugPrint('❌ Not recurring or no firebaseId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                : (highlightMyTask || isMyTask)
                ? friendGradientColors
                      .map((c) => c.withValues(alpha: 0.1))
                      .toList()
                : [Colors.white, const Color(0xFFFAFAFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                : (highlightMyTask || isMyTask)
                ? friendPrimaryColor.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : (highlightMyTask || isMyTask)
                  ? friendGlowColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (isMyTask)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: friendGradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
                                  )
                                : null,
                            color: isCompleted ? null : Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taskName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.grey.shade600
                                      : const Color(0xFF2C3E50),
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (assignedBy != null)
                                    _buildInfoChip(
                                      icon: isMyTask
                                          ? Icons.send_rounded
                                          : Icons.person_rounded,
                                      label: isMyTask
                                          ? 'By You'
                                          : 'By $assignedBy',
                                      color: friendPrimaryColor,
                                      backgroundColor: friendPrimaryColor
                                          .withValues(alpha: 0.12),
                                    )
                                  else
                                    _buildInfoChip(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Self-Created',
                                      color: friendGradientColors.length > 1
                                          ? friendGradientColors[1]
                                          : friendPrimaryColor,
                                      backgroundColor:
                                          (friendGradientColors.length > 1
                                                  ? friendGradientColors[1]
                                                  : friendPrimaryColor)
                                              .withValues(alpha: 0.12),
                                    ),
                                  // ✅ NEW: Recurring badge (show BEFORE timer badge)
                                  if (data['isRecurring'] == true)
                                    _buildInfoChip(
                                      icon: Icons.repeat_rounded,
                                      label: 'Daily',
                                      color: const Color(0xFF9C27B0),
                                      backgroundColor: const Color(
                                        0xFF9C27B0,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  if (hasTimer && totalDuration != null)
                                    _buildInfoChip(
                                      icon: Icons.timer_outlined,
                                      label:
                                          '${(totalDuration / 60).round()} min',
                                      color: const Color(0xFFFF9800),
                                      backgroundColor: const Color(
                                        0xFFFF9800,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  if (status == 'pending')
                                    _buildInfoChip(
                                      icon: Icons.pending_outlined,
                                      label: 'Awaiting Accept',
                                      color: const Color(0xFFFF6F00),
                                      backgroundColor: const Color(
                                        0xFFFF6F00,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  if (isCompleted)
                                    _buildInfoChip(
                                      icon: Icons.check_circle_outline,
                                      label: 'Done',
                                      color: const Color(0xFF4CAF50),
                                      backgroundColor: const Color(
                                        0xFF4CAF50,
                                      ).withValues(alpha: 0.12),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasTimer &&
                        totalDuration != null &&
                        timerProgress != null &&
                        !isCompleted) ...[
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${(timerProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(timerProgress),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: timerProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _getProgressGradient(
                                        timerProgress,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDuration(elapsedSeconds)} / ${_formatDuration(totalDuration)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return const Color(0xFF4CAF50);
    if (progress < 0.66) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  List<Color> _getProgressGradient(double progress) {
    if (progress < 0.33) {
      return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
    } else if (progress < 0.66) {
      return [const Color(0xFFFF9800), const Color(0xFFFFA726)];
    } else {
      return [const Color(0xFFEF5350), const Color(0xFFE57373)];
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(friendPrimaryColor),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Error occurred',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: friendGradientColors
                    .map((c) => c.withValues(alpha: 0.2))
                    .toList(),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: friendPrimaryColor),
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
        ],
      ),
    );
  }
}
