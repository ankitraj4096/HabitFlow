import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/component/customToast.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSelectionPage extends StatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  final FireStoreService _firestoreService = FireStoreService();
  
  bool isAutoThemeEnabled = true;
  int? selectedThemeId;
  int userCompletedTasks = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's completed tasks
      final stats = await _firestoreService.getUserStatistics();
      userCompletedTasks = stats['completedTasks'] ?? 0;

      // Get user's theme preferences from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          isAutoThemeEnabled = data?['autoThemeEnabled'] ?? true;
          selectedThemeId = data?['selectedThemeId'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveThemePreference(int themeId, bool autoEnabled) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'autoThemeEnabled': autoEnabled,
        'selectedThemeId': autoEnabled ? null : themeId,
      }, SetOptions(merge: true));

      setState(() {
        isAutoThemeEnabled = autoEnabled;
        selectedThemeId = autoEnabled ? null : themeId;
      });

      // Update provider with new theme
      if (context.mounted) {
        final tierProvider = context.read<TierThemeProvider>();
        if (autoEnabled) {
          await tierProvider.refreshTierTheme();
        } else {
          tierProvider.setCustomTheme(themeId);
        }
      }

      if (mounted) {
        CustomToast.success(context, 'Theme updated successfully!');
      }
    } catch (e) {
      print('Error saving theme preference: $e');
      if (mounted) {
        CustomToast.error(context, 'Failed to update theme');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Theme Selection'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tierProvider.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(tierProvider.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Selection'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E5F5), Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // Auto Theme Toggle
              _buildAutoThemeSection(tierProvider),
              
              const SizedBox(height: 32),
              
              // Theme Grid
              _buildThemeGrid(tierProvider),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoThemeSection(TierThemeProvider tierProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Theme changes with your tier',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAutoThemeEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Enable auto theme
                    await _saveThemePreference(tierProvider.tierId, true);
                  } else {
                    // Disable auto theme, keep current tier as selected
                    await _saveThemePreference(tierProvider.tierId, false);
                  }
                },
                activeColor: tierProvider.primaryColor,
              ),
            ],
          ),
          if (isAutoThemeEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tierProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tierProvider.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: tierProvider.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your theme will automatically update as you complete more tasks and unlock new tiers!',
                      style: TextStyle(
                        fontSize: 12,
                        color: tierProvider.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeGrid(TierThemeProvider tierProvider) {
    final allTiers = _getAllTiers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Available Themes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: allTiers.length,
          itemBuilder: (context, index) {
            final tier = allTiers[index];
            return _buildThemeCard(tier, tierProvider);
          },
        ),
      ],
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> tier, TierThemeProvider tierProvider) {
    final tierId = tier['id'] as int;
    final tierName = tier['name'] as String;
    final requiredTasks = tier['completedTasks'] as int;
    final gradient = (tier['gradient'] as List).map((e) => e as Color).toList();
    final isUnlocked = userCompletedTasks >= requiredTasks;
    final isSelected = !isAutoThemeEnabled && selectedThemeId == tierId;
    final isCurrentTier = tierProvider.tierId == tierId;

    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          CustomToast.warning(
            context,
            'Complete $requiredTasks tasks to unlock this theme',
          );
          return;
        }

        if (isAutoThemeEnabled) {
          CustomToast.info(
            context,
            'Turn off Auto Theme to select manually',
          );
          return;
        }

        _saveThemePreference(tierId, false);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? tierProvider.primaryColor
                : isUnlocked
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: tierProvider.glowColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? gradient
                          : gradient.map((c) => c.withOpacity(0.3)).toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Lock overlay
              if (!isUnlocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete $requiredTasks\ntasks to unlock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Content
              if (isUnlocked)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tier Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _firestoreService.getIconFromString(tier['icon']),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      // Tier Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tierName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$requiredTasks tasks',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Selected badge
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: tierProvider.primaryColor,
                      size: 18,
                    ),
                  ),
                ),

              // Current tier badge
              if (isCurrentTier && isAutoThemeEnabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        color: tierProvider.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAllTiers() {
    return [
      {
        "id": 1,
        "name": "The Initiate",
        "completedTasks": 1,
        "icon": "sparkles",
        "gradient": [Colors.grey, Colors.grey.shade700],
      },
      {
        "id": 2,
        "name": "The Seeker",
        "completedTasks": 5,
        "icon": "target",
        "gradient": [Colors.blue.shade400, Colors.blue.shade600],
      },
      {
        "id": 3,
        "name": "The Novice",
        "completedTasks": 10,
        "icon": "book",
        "gradient": [Colors.green.shade400, Colors.green.shade600],
      },
      {
        "id": 4,
        "name": "The Apprentice",
        "completedTasks": 25,
        "icon": "hammer",
        "gradient": [Colors.yellow.shade400, Colors.yellow.shade600],
      },
      {
        "id": 5,
        "name": "The Adept",
        "completedTasks": 50,
        "icon": "zap",
        "gradient": [Colors.orange.shade400, Colors.orange.shade600],
      },
      {
        "id": 6,
        "name": "The Disciplined",
        "completedTasks": 100,
        "icon": "shield",
        "gradient": [Colors.purple.shade400, Colors.purple.shade600],
      },
      {
        "id": 7,
        "name": "The Specialist",
        "completedTasks": 250,
        "icon": "award",
        "gradient": [Colors.pink.shade400, Colors.pink.shade600],
      },
      {
        "id": 8,
        "name": "The Expert",
        "completedTasks": 500,
        "icon": "crown",
        "gradient": [Colors.indigo.shade400, Colors.indigo.shade600],
      },
      {
        "id": 9,
        "name": "The Vanguard",
        "completedTasks": 1000,
        "icon": "flame",
        "gradient": [Colors.red.shade400, Colors.red.shade600],
      },
      {
        "id": 10,
        "name": "The Sentinel",
        "completedTasks": 1750,
        "icon": "eye",
        "gradient": [Colors.cyan.shade400, Colors.cyan.shade600],
      },
      {
        "id": 11,
        "name": "The Virtuoso",
        "completedTasks": 2500,
        "icon": "music",
        "gradient": [Colors.teal.shade400, Colors.teal.shade600],
      },
      {
        "id": 12,
        "name": "The Master",
        "completedTasks": 4000,
        "icon": "trophy",
        "gradient": [Colors.amber.shade400, Colors.amber.shade600],
      },
      {
        "id": 13,
        "name": "The Grandmaster",
        "completedTasks": 6000,
        "icon": "gem",
        "gradient": [Colors.green.shade400, Colors.green.shade600],
      },
      {
        "id": 14,
        "name": "The Titan",
        "completedTasks": 8000,
        "icon": "mountain",
        "gradient": [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
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
      },
    ];
  }
}
