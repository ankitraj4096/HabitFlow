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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        userCompletedTasks = data?['lifetimeCompletedTasks'] ?? 0;
        
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

      if (context.mounted) {
        final tierProvider = context.read<TierThemeProvider>();
        if (autoEnabled) {
          await tierProvider.refreshTierTheme();
        } else {
          tierProvider.setCustomTheme(themeId);
        }
      }

      if (mounted) {
        CustomToast.showSuccess(context, 'Theme updated successfully!');
      }
    } catch (e) {
      print('Error saving theme preference: $e');
      if (mounted) {
        CustomToast.showError(context, 'Failed to update theme');
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
              _buildAutoThemeSection(tierProvider),
              const SizedBox(height: 32),
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
                    await _saveThemePreference(tierProvider.tierId, true);
                  } else {
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
          CustomToast.showWarning(
            context,
            'Complete $requiredTasks tasks to unlock this theme',
          );
          return;
        }

        if (isAutoThemeEnabled) {
          CustomToast.showInfo(
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
              if (isUnlocked)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
        "name": "The Starter",
        "completedTasks": 0,
        "icon": "circle",
        "gradient": [const Color(0xFF64748B), const Color(0xFF334155)],
      },
      {
        "id": 2,
        "name": "The Awakened",
        "completedTasks": 10,
        "icon": "sunrise",
        "gradient": [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        "id": 3,
        "name": "The Seeker",
        "completedTasks": 50,
        "icon": "target",
        "gradient": [const Color(0xFFCD7F32), const Color(0xFFB87333)],
      },
      {
        "id": 4,
        "name": "The Novice",
        "completedTasks": 100,
        "icon": "book",
        "gradient": [const Color(0xFF10B981), const Color(0xFF059669)],
      },
      {
        "id": 5,
        "name": "The Apprentice",
        "completedTasks": 250,
        "icon": "hammer",
        "gradient": [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        "id": 6,
        "name": "The Adept",
        "completedTasks": 500,
        "icon": "zap",
        "gradient": [const Color(0xFFF97316), const Color(0xFFEA580C)],
      },
      {
        "id": 7,
        "name": "The Disciplined",
        "completedTasks": 1000,
        "icon": "shield",
        "gradient": [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      },
      {
        "id": 8,
        "name": "The Specialist",
        "completedTasks": 2500,
        "icon": "award",
        "gradient": [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      },
      {
        "id": 9,
        "name": "The Expert",
        "completedTasks": 5000,
        "icon": "crown",
        "gradient": [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      },
      {
        "id": 10,
        "name": "The Vanguard",
        "completedTasks": 10000,
        "icon": "flame",
        "gradient": [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      },
      {
        "id": 11,
        "name": "The Sentinel",
        "completedTasks": 15000,
        "icon": "eye",
        "gradient": [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      },
      {
        "id": 12,
        "name": "The Virtuoso",
        "completedTasks": 25000,
        "icon": "music",
        "gradient": [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      },
      {
        "id": 13,
        "name": "The Master",
        "completedTasks": 40000,
        "icon": "trophy",
        "gradient": [const Color(0xFFEAB308), const Color(0xFFCA8A04)],
      },
      {
        "id": 14,
        "name": "The Grandmaster",
        "completedTasks": 60000,
        "icon": "gem",
        "gradient": [const Color(0xFF22C55E), const Color(0xFF16A34A)],
      },
      {
        "id": 15,
        "name": "The Titan",
        "completedTasks": 75000,
        "icon": "mountain",
        "gradient": [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
      },
      {
        "id": 16,
        "name": "The Luminary",
        "completedTasks": 90000,
        "icon": "sun",
        "gradient": [
          const Color(0xFFFFD700),
          const Color(0xFFB8860B),
          const Color(0xFF8B6914),
        ],
      },
      {
        "id": 17,
        "name": "The Ascended",
        "completedTasks": 100000,
        "icon": "infinity",
        "gradient": [
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
          const Color(0xFF0F3460),
          const Color(0xFF533483),
        ],
      },
    ];
  }
}
