import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/notes/firestore.dart';

/// Provider that manages user tier colors and theme throughout the app
/// Automatically updates when tasks are completed
class TierThemeProvider extends ChangeNotifier {
  final FireStoreService _firestoreService = FireStoreService();

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _taskSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // Tier-related data
  Map<String, dynamic> _userTier = {};
  List<Color> _gradientColors = [
    const Color(0xFF7C4DFF),
    const Color(0xFF448AFF),
  ];
  Color _glowColor = const Color(0xFF7C4DFF);
  Color _primaryColor = const Color(0xFF7C4DFF);
  IconData _tierIcon = Icons.star;
  bool _isAnimated = false;
  bool _isLoading = true;
  int _lastCompletedTasksCount = 0;

  // New tier thresholds matching your 17-tier system
  static const List<int> _tierThresholds = [
    0,      // Tier 1: The Starter (slate blue)
    10,     // Tier 2: The Awakened (login purple gradient)
    50,     // Tier 3: The Seeker
    100,    // Tier 4: The Novice
    250,    // Tier 5: The Apprentice
    500,    // Tier 6: The Adept
    1000,   // Tier 7: The Disciplined
    2500,   // Tier 8: The Specialist
    5000,   // Tier 9: The Expert
    10000,  // Tier 10: The Vanguard
    15000,  // Tier 11: The Sentinel
    25000,  // Tier 12: The Virtuoso
    40000,  // Tier 13: The Master
    60000,  // Tier 14: The Grandmaster
    75000,  // Tier 15: The Titan
    90000,  // Tier 16: The Luminary
    100000, // Tier 17: The Ascended
  ];

  // Getters
  Map<String, dynamic> get userTier => _userTier;
  List<Color> get gradientColors => _gradientColors;
  Color get glowColor => _glowColor;
  Color get primaryColor => _primaryColor;
  IconData get tierIcon => _tierIcon;
  bool get isAnimated => _isAnimated;
  bool get isLoading => _isLoading;
  String get tierName => _userTier['name'] ?? 'The Starter';
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

      // Check if user document has lifetimeCompletedTasks field
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists ||
          userDoc.data() == null ||
          !userDoc.data()!.containsKey('lifetimeCompletedTasks')) {
        // Initialize for existing users
        debugPrint('Initializing lifetimeCompletedTasks for existing user');
        final stats = await _firestoreService.getUserStatistics();
        final completedTasks = stats['completedTasks'] ?? 0;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lifetimeCompletedTasks': completedTasks,
        }, SetOptions(merge: true));

        // Set initial tier
        _updateTierFromCount(completedTasks);
      }

      // Listen to user document for lifetimeCompletedTasks
      _startListeningToUserDoc(user.uid);

      // Start listening to task changes in real-time
      _startListeningToTasks(user.uid);
    } catch (e) {
      debugPrint('Error initializing tier theme: $e');
      _setDefaultTheme();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start listening to user document for lifetimeCompletedTasks
  void _startListeningToUserDoc(String userId) {
    _userSubscription?.cancel();

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (doc) async {
            if (doc.exists) {
              final data = doc.data();
              if (data != null) {
                // Check if lifetimeCompletedTasks exists
                if (!data.containsKey('lifetimeCompletedTasks')) {
                  // Initialize the field for existing users
                  try {
                    final stats = await _firestoreService.getUserStatistics();
                    final completedTasks = stats['completedTasks'] ?? 0;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({'lifetimeCompletedTasks': completedTasks});

                    _updateTierFromCount(completedTasks);
                  } catch (e) {
                    debugPrint('Error initializing lifetimeCompletedTasks: $e');
                    _updateTierFromCount(0);
                  }
                } else {
                  final lifetimeCompleted = data['lifetimeCompletedTasks'] ?? 0;
                  _updateTierFromCount(lifetimeCompleted);
                }
              }
            } else {
              // User doc doesn't exist, set default
              _setDefaultTheme();
              _isLoading = false;
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('Error listening to user doc: $error');
            _setDefaultTheme();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Start listening to Firestore task changes in real-time
  void _startListeningToTasks(String userId) {
    _taskSubscription?.cancel();

    _taskSubscription = FirebaseFirestore.instance
        .collection('user_notes')
        .doc(userId)
        .collection('notes')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen(
          (snapshot) {
            _onTasksChanged(snapshot);
          },
          onError: (error) {
            debugPrint('Error listening to tasks: $error');
          },
        );
  }

  /// Handle task changes and update tier if necessary
  void _onTasksChanged(QuerySnapshot snapshot) {
    // Count completed tasks in current list
    int completedTasks = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isCompleted'] == true) {
        completedTasks++;
      }
    }

    // Only update if completed tasks count changed
    if (completedTasks != _lastCompletedTasksCount) {
      debugPrint('Tasks completed: $_lastCompletedTasksCount → $completedTasks');
      _lastCompletedTasksCount = completedTasks;
    }
  }

  /// Update tier based on lifetime completed tasks count
  void _updateTierFromCount(int completedTasks) {
    final newTier = _firestoreService.getUserTier(completedTasks);
    final oldTierId = _userTier['id'] ?? 0;
    final newTierId = newTier['id'] ?? 0;

    // Only update if tier actually changed
    if (oldTierId != newTierId) {
      debugPrint('🎉 Tier upgraded: $oldTierId → $newTierId');
      _userTier = newTier;
      _extractTierTheme();
      notifyListeners();
    } else if (oldTierId == 0) {
      // First initialization
      _userTier = newTier;
      _extractTierTheme();
      notifyListeners();
    }
  }

  /// Manually refresh tier theme (for pull-to-refresh scenarios)
  Future<void> refreshTierTheme() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final lifetimeCompleted = userDoc.data()?['lifetimeCompletedTasks'] ?? 0;

      final newTier = _firestoreService.getUserTier(lifetimeCompleted);
      _userTier = newTier;
      _extractTierTheme();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing tier theme: $e');
    }
  }

  /// Set a custom theme (manually selected by user)
  void setCustomTheme(int tierId) {
    if (tierId > 0 && tierId <= _tierThresholds.length) {
      final requiredTasks = _tierThresholds[tierId - 1];
      _userTier = _firestoreService.getUserTier(requiredTasks);
      _extractTierTheme();
      notifyListeners();
    }
  }

  /// Get all available tiers (for theme selection page)
  List<Map<String, dynamic>> getAllTiers() {
    return _tierThresholds.map((requiredTasks) {
      return _firestoreService.getUserTier(requiredTasks);
    }).toList();
  }

  /// Extract theme colors and properties from user tier
  void _extractTierTheme() {
    // Extract gradient colors or single color
    final gradient = _userTier['gradient'] as List?;
    final color = _userTier['color'] as Color?;

    if (gradient != null && gradient.isNotEmpty) {
      _gradientColors = gradient.map((e) => e as Color).toList();
      _primaryColor = _gradientColors.first;
    } else if (color != null) {
      // Use single color (for tiers like "The Starter")
      _gradientColors = [color, color.withValues(alpha: 0.8)];
      _primaryColor = color;
    } else {
      // Default fallback
      _gradientColors = [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
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
    _userTier = _firestoreService.getUserTier(0); // Pass 0 for users with no tasks

    // If tier data is incomplete, set manual fallback
    if (_userTier.isEmpty || !_userTier.containsKey('id')) {
      _userTier = {
        "id": 1,
        "name": "The Starter",
        "completedTasks": 0,
        "icon": "circle",
        "gradient": [
          const Color(0xFF64748B), // Slate blue
          const Color(0xFF334155), // Deep slate
        ],
        "glow": const Color(0xFF94A3B8),
      };
    }

    _extractTierTheme();
  }

  /// Get tier progress to next level
  Map<String, dynamic> getTierProgress() {
    final currentTierId = _userTier['id'] ?? 1;
    final currentIndex = currentTierId - 1;

    if (currentIndex >= _tierThresholds.length - 1) {
      return {
        'current': _tierThresholds[currentIndex],
        'next': null,
        'progress': 1.0,
        'isMaxTier': true,
      };
    }

    final current = _tierThresholds[currentIndex];
    final next = _tierThresholds[currentIndex + 1];

    // Get actual completed tasks count
    final completedTasks = _lastCompletedTasksCount;

    // Calculate progress between current and next tier
    final progress = ((completedTasks - current) / (next - current)).clamp(
      0.0,
      1.0,
    );

    return {
      'current': current,
      'next': next,
      'progress': progress,
      'isMaxTier': false,
      'completedTasks': completedTasks,
    };
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
