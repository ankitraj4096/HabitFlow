import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DailyCompletedTasksPage extends StatelessWidget {
  final DateTime selectedDate;
  final String? viewingUserID; // null if viewing own tasks
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
              _buildHeader(context),
              Expanded(child: _buildTasksList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateStr = '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.3),
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
                        isOwnProfile ? 'Your Completed Tasks' : '${viewingUsername}\'s Tasks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
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
    final userID = isOwnProfile ? FirebaseAuth.instance.currentUser?.uid : viewingUserID;
    
    if (userID == null) {
      return _buildEmptyState('Unable to load tasks');
    }

    // Get start and end of the selected date
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_notes')
          .doc(userID)
          .collection('notes')
          .where('isCompleted', isEqualTo: true)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmptyState('Error loading tasks');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
            ),
          );
        }

        // Filter tasks completed on the selected date
        final completedTasksOnDate = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final completedAt = data['completedAt'] as Timestamp?;
          
          if (completedAt == null) return false;
          
          final completedDate = completedAt.toDate();
          return completedDate.isAfter(startOfDay) && completedDate.isBefore(endOfDay);
        }).toList();

        if (completedTasksOnDate.isEmpty) {
          return _buildEmptyState('No tasks completed on this day');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedTasksOnDate.length,
          itemBuilder: (context, index) {
            final doc = completedTasksOnDate[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTaskCard(data);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> taskData) {
    final taskName = taskData['taskName'] ?? 'Unnamed Task';
    final completedAt = taskData['completedAt'] as Timestamp?;
    final hasTimer = taskData['hasTimer'] ?? false;
    final elapsedSeconds = taskData['elapsedSeconds'] ?? 0;
    final assignedBy = taskData['assignedByUsername'];

    String timeStr = 'Unknown time';
    if (completedAt != null) {
      final completedDate = completedAt.toDate();
      timeStr = '${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}';
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
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
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
                // Checkmark Icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                // Task Name
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
                // Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Color(0xFF4CAF50)),
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
            if (assignedBy != null || hasTimer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (assignedBy != null) ...[
                    Icon(Icons.person, size: 14, color: Colors.purple.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'By: $assignedBy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasTimer) const SizedBox(width: 12),
                  ],
                  if (hasTimer) ...[
                    Icon(Icons.timer, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(elapsedSeconds),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Color(0xFF7C4DFF),
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
