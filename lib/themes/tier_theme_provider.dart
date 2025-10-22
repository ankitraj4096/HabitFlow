import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/notes/firestore.dart';

/// Provider that manages user tier colors and theme throughout the app
/// Automatically updates when tasks are completed
class TierThemeProvider extends ChangeNotifier {
  final FireStoreService _firestoreService = FireStoreService();
  
  // Stream subscription for listening to task changes
  StreamSubscription<QuerySnapshot>? _taskSubscription;
  
  // Tier-related data
  Map<String, dynamic> _userTier = {};
  List<Color> _gradientColors = [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
  Color _glowColor = const Color(0xFF7C4DFF);
  Color _primaryColor = const Color(0xFF7C4DFF);
  IconData _tierIcon = Icons.star;
  bool _isAnimated = false;
  bool _isLoading = true;
  int _lastCompletedTasksCount = 0;
  
  // Getters
  Map<String, dynamic> get userTier => _userTier;
  List<Color> get gradientColors => _gradientColors;
  Color get glowColor => _glowColor;
  Color get primaryColor => _primaryColor;
  IconData get tierIcon => _tierIcon;
  bool get isAnimated => _isAnimated;
  bool get isLoading => _isLoading;
  String get tierName => _userTier['name'] ?? 'The Initiate';
  int get tierId => _userTier['id'] ?? 1;
  
  /// Initialize the tier theme and start listening to task changes
  Future<void> initializeTierTheme() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setDefaultTheme();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get initial statistics
      final stats = await _firestoreService.getUserStatistics();
      final completedTasks = stats['completedTasks'] ?? 0;
      _lastCompletedTasksCount = completedTasks;
      
      // Get user tier based on completed tasks
      _userTier = _firestoreService.getUserTier(completedTasks);
      
      // Extract colors and properties from tier
      _extractTierTheme();
      
      // Start listening to task changes in real-time
      _startListeningToTasks(user.uid);
      
    } catch (e) {
      print('Error initializing tier theme: $e');
      _setDefaultTheme();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Start listening to Firestore task changes in real-time
  void _startListeningToTasks(String userId) {
    // Cancel any existing subscription
    _taskSubscription?.cancel();
    
    // Listen to the user's tasks collection
    _taskSubscription = FirebaseFirestore.instance
        .collection('user_notes')
        .doc(userId)
        .collection('notes')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      _onTasksChanged(snapshot);
    }, onError: (error) {
      print('Error listening to tasks: $error');
    });
  }
  
  /// Handle task changes and update tier if necessary
  void _onTasksChanged(QuerySnapshot snapshot) {
    // Count completed tasks
    int completedTasks = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isCompleted'] == true) {
        completedTasks++;
      }
    }
    
    // Only update if completed tasks count changed
    if (completedTasks != _lastCompletedTasksCount) {
      print('Tasks completed: $_lastCompletedTasksCount → $completedTasks');
      _lastCompletedTasksCount = completedTasks;
      
      // Get new tier
      final newTier = _firestoreService.getUserTier(completedTasks);
      final oldTierId = _userTier['id'] ?? 0;
      final newTierId = newTier['id'] ?? 0;
      
      // Only update if tier actually changed
      if (oldTierId != newTierId) {
        print('🎉 Tier upgraded: $oldTierId → $newTierId');
        _userTier = newTier;
        _extractTierTheme();
        notifyListeners(); // ← This triggers UI rebuild!
      }
    }
  }
  
  /// Manually refresh tier theme (for pull-to-refresh scenarios)
  Future<void> refreshTierTheme() async {
    try {
      final stats = await _firestoreService.getUserStatistics();
      final completedTasks = stats['completedTasks'] ?? 0;
      _lastCompletedTasksCount = completedTasks;
      
      final newTier = _firestoreService.getUserTier(completedTasks);
      _userTier = newTier;
      _extractTierTheme();
      notifyListeners();
    } catch (e) {
      print('Error refreshing tier theme: $e');
    }
  }
  
  /// Extract theme colors and properties from user tier
  void _extractTierTheme() {
    // Extract gradient colors
    final gradient = _userTier['gradient'] as List?;
    if (gradient != null && gradient.isNotEmpty) {
      _gradientColors = gradient.map((e) => e as Color).toList();
      _primaryColor = _gradientColors.first;
    }
    
    // Extract glow color
    _glowColor = _userTier['glow'] as Color? ?? const Color(0xFF7C4DFF);
    
    // Extract icon
    final iconName = _userTier['icon'] as String?;
    if (iconName != null) {
      _tierIcon = _firestoreService.getIconFromString(iconName);
    }
    
    // Check if tier is animated
    _isAnimated = _userTier['animated'] == true;
  }
  
  /// Set default theme values
  void _setDefaultTheme() {
    _userTier = {
      'id': 1,
      'name': 'The Initiate',
      'completedTasks': 1,
      'icon': 'sparkles',
      'gradient': [Colors.grey, Colors.grey.shade700],
      'glow': Colors.grey,
    };
    _extractTierTheme();
  }
  
  /// Get tier progress to next level
  Map<String, dynamic> getTierProgress() {
    final allTiers = [
      1, 5, 10, 25, 50, 100, 250, 500, 1000, 1750, 2500, 4000, 6000, 8000, 10000, 10001
    ];
    
    final currentTierId = _userTier['id'] ?? 1;
    final currentIndex = currentTierId - 1;
    
    if (currentIndex >= allTiers.length - 1) {
      return {
        'current': allTiers[currentIndex],
        'next': null,
        'progress': 1.0,
        'isMaxTier': true,
      };
    }
    
    final current = allTiers[currentIndex];
    final next = allTiers[currentIndex + 1];
    final progress = (current / next).clamp(0.0, 1.0);
    
    return {
      'current': current,
      'next': next,
      'progress': progress,
      'isMaxTier': false,
    };
  }
  
  @override
  void dispose() {
    // Cancel the stream subscription when provider is disposed
    _taskSubscription?.cancel();
    super.dispose();
  }
}
