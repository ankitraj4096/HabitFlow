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
        .listen(
          (snapshot) {
            _onTasksChanged(snapshot);
          },
          onError: (error) {
            print('Error listening to tasks: $error');
          },
        );
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

  /// Set a custom theme (manually selected by user)
  void setCustomTheme(int tierId) {
    final allTiers = _getAllAllTiers();
    final selectedTier = allTiers.firstWhere(
      (tier) => tier['id'] == tierId,
      orElse: () => allTiers[0],
    );

    _userTier = selectedTier;
    _extractTierTheme();
    notifyListeners();
  }

  /// Get all available tiers
  List<Map<String, dynamic>> _getAllAllTiers() {
    return [
      {
        "id": 1,
        "name": "The Initiate",
        "completedTasks": 1,
        "icon": "sparkles",
        "gradient": [Colors.grey, Colors.grey.shade700],
        "glow": Colors.grey,
      },
      {
        "id": 2,
        "name": "The Seeker",
        "completedTasks": 5,
        "icon": "target",
        "gradient": [Colors.blue.shade400, Colors.blue.shade600],
        "glow": Colors.blue,
      },
      {
        "id": 3,
        "name": "The Novice",
        "completedTasks": 10,
        "icon": "book",
        "gradient": [Colors.green.shade400, Colors.green.shade600],
        "glow": Colors.green,
      },
      {
        "id": 4,
        "name": "The Apprentice",
        "completedTasks": 25,
        "icon": "hammer",
        "gradient": [Colors.yellow.shade400, Colors.yellow.shade600],
        "glow": Colors.yellow,
      },
      {
        "id": 5,
        "name": "The Adept",
        "completedTasks": 50,
        "icon": "zap",
        "gradient": [Colors.orange.shade400, Colors.orange.shade600],
        "glow": Colors.orange,
      },
      {
        "id": 6,
        "name": "The Disciplined",
        "completedTasks": 100,
        "icon": "shield",
        "gradient": [Colors.purple.shade400, Colors.purple.shade600],
        "glow": Colors.purple,
      },
      {
        "id": 7,
        "name": "The Specialist",
        "completedTasks": 250,
        "icon": "award",
        "gradient": [Colors.pink.shade400, Colors.pink.shade600],
        "glow": Colors.pink,
      },
      {
        "id": 8,
        "name": "The Expert",
        "completedTasks": 500,
        "icon": "crown",
        "gradient": [Colors.indigo.shade400, Colors.indigo.shade600],
        "glow": Colors.indigo,
      },
      {
        "id": 9,
        "name": "The Vanguard",
        "completedTasks": 1000,
        "icon": "flame",
        "gradient": [Colors.red.shade400, Colors.red.shade600],
        "glow": Colors.red,
      },
      {
        "id": 10,
        "name": "The Sentinel",
        "completedTasks": 1750,
        "icon": "eye",
        "gradient": [Colors.cyan.shade400, Colors.cyan.shade600],
        "glow": Colors.cyan,
      },
      {
        "id": 11,
        "name": "The Virtuoso",
        "completedTasks": 2500,
        "icon": "music",
        "gradient": [Colors.teal.shade400, Colors.teal.shade600],
        "glow": Colors.teal,
      },
      {
        "id": 12,
        "name": "The Master",
        "completedTasks": 4000,
        "icon": "trophy",
        "gradient": [Colors.amber.shade400, Colors.amber.shade600],
        "glow": Colors.amber,
      },
      {
        "id": 13,
        "name": "The Grandmaster",
        "completedTasks": 6000,
        "icon": "gem",
        "gradient": [Colors.lightGreen.shade400, Colors.lightGreen.shade600],
        "glow": Colors.lightGreen,
      },
      {
        "id": 14,
        "name": "The Titan",
        "completedTasks": 8000,
        "icon": "mountain",
        "gradient": [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
        "glow": Colors.blueGrey,
      },
      {
        "id": 15,
        "name": "The Luminary",
        "completedTasks": 10000,
        "icon": "sun",
        "gradient": [
          Colors.yellow.shade300,
          Colors.orange.shade400,
          Colors.red.shade500,
        ],
        "glow": Colors.orange,
        "animated": true,
      },
      {
        "id": 16,
        "name": "The Ascended",
        "completedTasks": 10001,
        "icon": "infinity",
        "gradient": [
          Colors.purple.shade400,
          Colors.pink.shade500,
          Colors.yellow.shade400,
        ],
        "glow": Colors.purple,
        "animated": true,
      },
    ];
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
      1,
      5,
      10,
      25,
      50,
      100,
      250,
      500,
      1000,
      1750,
      2500,
      4000,
      6000,
      8000,
      10000,
      10001,
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
