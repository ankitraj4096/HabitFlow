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
  int lifetimeCompletedTasks = 0;
  int totalHours = 0;
  Map<String, dynamic> userTier = {};
  Map<String, int> heatmapData = {};
  bool isLoading = true;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;

  UserStatsProvider() {
    _startAuthListener();
  }

  /// ✅ NEW: Listen to auth state changes
  void _startAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        debugPrint('📊 UserStats - Auth state changed: ${user?.uid}');
        
        if (user == null) {
          // User logged out
          _handleUserLogout();
        } else if (_currentUserId != user.uid) {
          // User logged in or switched accounts
          _handleUserLogin(user.uid);
        }
      },
      onError: (error) {
        debugPrint('Error in auth listener: $error');
      },
    );
  }

  /// ✅ NEW: Handle user login/switch
  void _handleUserLogin(String userId) {
    debugPrint('📊 UserStats - User logged in: $userId');
    
    // Cancel previous user's subscriptions
    _cancelSubscriptions();
    
    // Reset to loading state
    _resetToDefaultState();
    
    // Update current user
    _currentUserId = userId;
    
    // Initialize for new user
    _initialize();
  }

  /// ✅ NEW: Handle user logout
  void _handleUserLogout() {
    debugPrint('📊 UserStats - User logged out');
    
    // Cancel all subscriptions
    _cancelSubscriptions();
    
    // Reset everything
    _currentUserId = null;
    _resetToDefaultState();
    notifyListeners();
  }

  /// ✅ NEW: Cancel all active subscriptions
  void _cancelSubscriptions() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  /// ✅ NEW: Reset to default state
  void _resetToDefaultState() {
    username = 'Loading...';
    currentStreak = 0;
    totalTasks = 0;
    completedTasks = 0;
    lifetimeCompletedTasks = 0;
    totalHours = 0;
    userTier = {};
    heatmapData = {};
    isLoading = true;
  }

  void _initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _listenToTasks();
      _listenToUserDoc();
    }
  }

  /// Listen to user document for lifetime count
  void _listenToUserDoc() {
    _userSubscription?.cancel();
    
    if (_currentUserId == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .listen((doc) {
      // ✅ Check if this is still the current user
      if (_currentUserId != doc.id) {
        debugPrint('⚠️ UserStats - Ignoring update for old user: ${doc.id}');
        return;
      }

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
      // ✅ Check if this is still the current user
      if (_currentUserId != FirebaseAuth.instance.currentUser?.uid) {
        debugPrint('⚠️ UserStats - Ignoring task update for old user');
        return;
      }
      _calculateStats(snapshot);
    });
  }

  /// Calculate all stats from snapshot
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

      // Update all values
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
    if (_currentUserId == null) return;

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
    _authSubscription?.cancel();
    _tasksSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
