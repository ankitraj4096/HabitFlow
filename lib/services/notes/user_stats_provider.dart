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

  /// Listen to auth state changes
  void _startAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        debugPrint('📊 UserStats - Auth state changed: ${user?.uid}');
        
        if (user == null) {
          _handleUserLogout();
        } else if (_currentUserId != user.uid) {
          _handleUserLogin(user.uid);
        }
      },
      onError: (error) {
        debugPrint('Error in auth listener: $error');
      },
    );
  }

  /// Handle user login/switch
  void _handleUserLogin(String userId) {
    debugPrint('📊 UserStats - User logged in: $userId');
    
    _cancelSubscriptions();
    _resetToDefaultState();
    _currentUserId = userId;
    _initialize();
  }

  /// Handle user logout
  void _handleUserLogout() {
    debugPrint('📊 UserStats - User logged out');
    
    _cancelSubscriptions();
    _currentUserId = null;
    _resetToDefaultState();
    notifyListeners();
  }

  /// Cancel all active subscriptions
  void _cancelSubscriptions() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  /// Reset to default state
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
      if (_currentUserId != doc.id) {
        debugPrint('⚠️ UserStats - Ignoring update for old user: ${doc.id}');
        return;
      }

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          lifetimeCompletedTasks = data['lifetimeCompletedTasks'] ?? 0;
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
      if (_currentUserId != FirebaseAuth.instance.currentUser?.uid) {
        debugPrint('⚠️ UserStats - Ignoring task update for old user');
        return;
      }
      _calculateStats(snapshot);
    });
  }

  /// ✅ FIXED: Changed to Future<void> so await works
  Future<void> _calculateStats(QuerySnapshot snapshot) async {
    try {
      final name = await _firestoreService.getUsername();

      int total = snapshot.docs.length;
      int completed = 0;
      int hours = 0;
      Map<String, int> completions = {};
      Map<String, int> heatmap = {};

      // Calculate stats from current tasks
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Count completed tasks
        if (data['isCompleted'] == true) {
          completed++;
          
          final completedAt = data['completedAt'] as Timestamp?;
          if (completedAt != null) {
            final dateKey = _formatDate(completedAt.toDate());
            completions[dateKey] = (completions[dateKey] ?? 0) + 1;
            heatmap[dateKey] = (heatmap[dateKey] ?? 0) + 1;
          }
        }

        // ✅ For recurring tasks, fetch their history
        if (data['isRecurring'] == true) {
          await _addRecurringHistoryToHeatmap(doc.id, heatmap, completions);
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

  /// ✅ Add recurring task history to heatmap
  Future<void> _addRecurringHistoryToHeatmap(
    String taskId,
    Map<String, int> heatmap,
    Map<String, int> completions,
  ) async {
    try {
      if (_currentUserId == null) return;

      final historySnapshot = await FirebaseFirestore.instance
          .collection('recurringHistory')
          .doc(_currentUserId)
          .collection(taskId)
          .doc('completions')
          .collection('dates')
          .get();

      for (var doc in historySnapshot.docs) {
        final dateKey = doc.id; // Date is the document ID (YYYY-MM-DD)
        
        // Add to heatmap and completions (but don't double count today)
        final today = _formatDate(DateTime.now());
        if (dateKey != today) {
          heatmap[dateKey] = (heatmap[dateKey] ?? 0) + 1;
          completions[dateKey] = (completions[dateKey] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint('Error fetching recurring history: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate streak
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
      
      await _calculateStats(snapshot);
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
