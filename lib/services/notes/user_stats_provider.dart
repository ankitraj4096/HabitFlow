import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserStatsProvider extends ChangeNotifier {
  final FireStoreService _firestoreService = FireStoreService();
  
  // User stats
  String username = 'Loading...';
  int currentStreak = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int lifetimeCompletedTasks = 0; // ✅ NEW: Lifetime counter
  int totalHours = 0;
  Map<String, dynamic> userTier = {};
  Map<String, int> heatmapData = {};
  bool isLoading = true;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  String? _currentUserId;

  UserStatsProvider() {
    _initialize();
  }

  void _initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _listenToTasks();
      _listenToUserDoc(); // ✅ NEW: Listen to user document
    }
  }

  // ✅ NEW: Listen to user document for lifetime count
  void _listenToUserDoc() {
    _userSubscription?.cancel();
    
    if (_currentUserId == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          lifetimeCompletedTasks = data['lifetimeCompletedTasks'] ?? 0;
          
          // Update tier based on lifetime count
          userTier = _firestoreService.getUserTier(lifetimeCompletedTasks);
          notifyListeners();
        }
      }
    });
  }

  void _listenToTasks() {
    _tasksSubscription?.cancel();
    
    if (_currentUserId == null) return;

    _tasksSubscription = FirebaseFirestore.instance
        .collection('user_notes')
        .doc(_currentUserId)
        .collection('notes')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      _calculateStats(snapshot);
    });
  }

  /// Calculate all stats from snapshot - FIXED to use completedAt
  void _calculateStats(QuerySnapshot snapshot) async {
    try {
      // Get username
      final name = await _firestoreService.getUsername();

      // Calculate stats from tasks
      int total = snapshot.docs.length;
      int completed = 0;
      int hours = 0;
      Map<String, int> completions = {};
      Map<String, int> heatmap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['isCompleted'] == true) {
          completed++;
          
          // ✅ FIXED: Changed from 'timestamp' to 'completedAt'
          final completedAt = data['completedAt'] as Timestamp?;
          if (completedAt != null) {
            final dateKey = _formatDate(completedAt.toDate());
            completions[dateKey] = (completions[dateKey] ?? 0) + 1;
            heatmap[dateKey] = (heatmap[dateKey] ?? 0) + 1;
          }
        }

        // Calculate hours from elapsed time
        if (data['hasTimer'] == true && data['elapsedSeconds'] != null) {
          hours += (data['elapsedSeconds'] as int) ~/ 3600;
        }
      }

      // Calculate streak
      int streak = _calculateStreak(completions);

      // Update all values (tier is updated from user doc listener)
      username = name;
      currentStreak = streak;
      totalTasks = total;
      completedTasks = completed;
      totalHours = hours;
      heatmapData = heatmap;
      isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating stats: $e');
      isLoading = false;
      notifyListeners();
    }
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

  /// Manually refresh data
  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_notes')
          .doc(_currentUserId)
          .collection('notes')
          .where('status', isEqualTo: 'accepted')
          .get();
      
      _calculateStats(snapshot);
    } catch (e) {
      debugPrint('Error refreshing stats: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _userSubscription?.cancel(); // ✅ NEW: Dispose user subscription
    super.dispose();
  }
}
