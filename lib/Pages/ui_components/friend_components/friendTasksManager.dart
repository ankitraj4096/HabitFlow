import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed to 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _showAssignTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3E5F5), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_add_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assign Task to ${widget.friendUsername}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C4DFF),
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'What should they do?',
                  prefixIcon: Icon(Icons.task, color: Color(0xFF7C4DFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Timer (minutes) - Optional',
                  hintText: 'e.g., 30 minutes',
                  prefixIcon: Icon(Icons.timer, color: Color(0xFF448AFF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF448AFF), width: 2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _taskController.clear();
                      _timerController.clear();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_taskController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a task name')),
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
                        );

                        Navigator.pop(context);
                        _taskController.clear();
                        _timerController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Task assigned to ${widget.friendUsername}!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to assign task: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C4DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Assign Task',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
        backgroundColor: Color(0xFF7C4DFF),
        icon: Icon(Icons.add),
        label: Text('Assign Task'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C4DFF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.friendUsername}\'s Tasks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
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
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7C4DFF).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
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
    // Get all tasks from friend's collection (no status filtering)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_notes')
          .doc(widget.friendUserID)
          .collection('notes')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading tasks: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Filter: show accepted tasks OR tasks without status (old tasks)
        final allTasks =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];
              return status == 'accepted' ||
                  status == null; // Include old tasks
            }).toList() ??
            [];

        if (allTasks.isEmpty) {
          return _buildEmptyState('No tasks yet', Icons.task_alt);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: allTasks.length,
          itemBuilder: (context, index) {
            final data = allTasks[index].data() as Map<String, dynamic>;
            return _buildTaskCard(data);
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

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTaskCard(data, highlightMyTask: true);
          },
        );
      },
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

    // Calculate progress for tasks with timers
    double? timerProgress;
    if (hasTimer && totalDuration != null && totalDuration > 0) {
      timerProgress = (elapsedSeconds / totalDuration).clamp(0.0, 1.0);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]
              : (highlightMyTask || isMyTask)
              ? [Color(0xFFEDE7F6), Color(0xFFD1C4E9)]
              : [Colors.white, Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Color(0xFF4CAF50).withOpacity(0.3)
              : (highlightMyTask || isMyTask)
              ? Color(0xFF7C4DFF).withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Color(0xFF4CAF50).withOpacity(0.1)
                : (highlightMyTask || isMyTask)
                ? Color(0xFF7C4DFF).withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Left accent bar
            if (isMyTask)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completion Icon with animation effect
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
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
                                    color: Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: isCompleted
                            ? Icon(
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
                      SizedBox(width: 14),

                      // Task Name and Details
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
                                    : Color(0xFF2C3E50),
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),

                            // Status Row with better visual hierarchy
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // Assignment Badge
                                if (assignedBy != null)
                                  _buildInfoChip(
                                    icon: isMyTask
                                        ? Icons.send_rounded
                                        : Icons.person_rounded,
                                    label: isMyTask
                                        ? 'By You'
                                        : 'By $assignedBy',
                                    color: isMyTask
                                        ? Color(0xFF7C4DFF)
                                        : Color(0xFF9C27B0),
                                    backgroundColor: isMyTask
                                        ? Color(0xFF7C4DFF).withOpacity(0.12)
                                        : Color(0xFF9C27B0).withOpacity(0.12),
                                  )
                                else
                                  _buildInfoChip(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Self-Created',
                                    color: Color(0xFF448AFF),
                                    backgroundColor: Color(
                                      0xFF448AFF,
                                    ).withOpacity(0.12),
                                  ),

                                // Timer Badge
                                if (hasTimer && totalDuration != null)
                                  _buildInfoChip(
                                    icon: Icons.timer_outlined,
                                    label:
                                        '${(totalDuration / 60).round()} min',
                                    color: Color(0xFFFF9800),
                                    backgroundColor: Color(
                                      0xFFFF9800,
                                    ).withOpacity(0.12),
                                  ),

                                // Status Badge
                                if (status == 'pending')
                                  _buildInfoChip(
                                    icon: Icons.pending_outlined,
                                    label: 'Awaiting Accept',
                                    color: Color(0xFFFF6F00),
                                    backgroundColor: Color(
                                      0xFFFF6F00,
                                    ).withOpacity(0.12),
                                  ),

                                // Completion Badge
                                if (isCompleted)
                                  _buildInfoChip(
                                    icon: Icons.check_circle_outline,
                                    label: 'Done',
                                    color: Color(0xFF4CAF50),
                                    backgroundColor: Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.12),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Timer Progress Bar (if applicable)
                  if (hasTimer &&
                      totalDuration != null &&
                      timerProgress != null &&
                      !isCompleted) ...[
                    SizedBox(height: 14),
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
                        SizedBox(height: 6),
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
                                    colors: _getProgressGradient(timerProgress),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
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
    );
  }

  // Helper widget for info chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 5),
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

  // Helper method for progress color
  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Color(0xFF4CAF50);
    if (progress < 0.66) return Color(0xFFFF9800);
    return Color(0xFFEF5350);
  }

  // Helper method for progress gradient
  List<Color> _getProgressGradient(double progress) {
    if (progress < 0.33) {
      return [Color(0xFF4CAF50), Color(0xFF66BB6A)];
    } else if (progress < 0.66) {
      return [Color(0xFFFF9800), Color(0xFFFFA726)];
    } else {
      return [Color(0xFFEF5350), Color(0xFFE57373)];
    }
  }

  // Helper method for duration formatting
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
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          SizedBox(height: 16),
          Text(
            'Error occurred',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
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
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Color(0xFF7C4DFF)),
          ),
          SizedBox(height: 24),
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
