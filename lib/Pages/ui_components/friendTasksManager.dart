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
                    child: Icon(Icons.person_add_alt, color: Colors.white, size: 24),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
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
                            content: Text('Task assigned to ${widget.friendUsername}!'),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Assign Task', style: TextStyle(color: Colors.white)),
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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: 'All Tasks'),
          Tab(text: 'Assigned by Me'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllTasksTab(),
        _buildTasksByMeTab(),
      ],
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
        final allTasks = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];
          return status == 'accepted' || status == null; // Include old tasks
        }).toList() ?? [];

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
          return _buildErrorState('Error loading your assigned tasks: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('You haven\'t assigned any tasks yet', Icons.person_add_alt);
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

  Widget _buildTaskCard(Map<String, dynamic> data, {bool highlightMyTask = false}) {
    final taskName = data['taskName'] ?? 'Unnamed Task';
    final isCompleted = data['isCompleted'] ?? false;
    final assignedBy = data['assignedByUsername'];
    final status = data['status'] ?? 'accepted';
    final hasTimer = data['hasTimer'] ?? false;
    final totalDuration = data['totalDuration'];
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final isMyTask = data['assignedByUserID'] == currentUserID;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: highlightMyTask || isMyTask
            ? Color(0xFF7C4DFF).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightMyTask || isMyTask
              ? Color(0xFF7C4DFF).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Completion Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Color(0xFF4CAF50) : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                SizedBox(width: 12),
                
                // Task Name
                Expanded(
                  child: Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Status Badge
                if (status == 'pending')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Assigned by section
            if (assignedBy != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isMyTask ? Icons.send : Icons.person, 
                    size: 14, 
                    color: isMyTask ? Colors.green : Colors.purple
                  ),
                  SizedBox(width: 4),
                  Text(
                    isMyTask ? 'Assigned by: You' : 'Assigned by: $assignedBy',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMyTask ? Colors.green : Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Self-created task',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Timer info
            if (hasTimer && totalDuration != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Color(0xFF448AFF)),
                  SizedBox(width: 4),
                  Text(
                    '${(totalDuration / 60).round()} minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF448AFF),
                      fontWeight: FontWeight.w500,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
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
