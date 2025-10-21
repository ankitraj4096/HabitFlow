import 'package:demo/services/notes/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage>
    with SingleTickerProviderStateMixin {
  final FireStoreService _firestoreService = FireStoreService();

  int completedTasks = 0;
  Map<String, dynamic> currentTier = {};
  Map<String, dynamic>? nextTier;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // All tier data (matching your structure)
  final List<Map<String, dynamic>> allTiers = [
    {
      'id': 1,
      'name': 'The Initiate',
      'requirement': 1,
      'icon': 'sparkles',
      'color': Colors.grey,
      'description': 'Welcome! Begin your journey to productivity.',
    },
    {
      'id': 2,
      'name': 'The Seeker',
      'requirement': 5,
      'icon': 'target',
      'color': Colors.blue,
      'description': 'You\'re discovering your path. Keep going!',
    },
    {
      'id': 3,
      'name': 'The Novice',
      'requirement': 10,
      'icon': 'book',
      'color': Colors.green,
      'description': 'Learning the ropes. Great progress!',
    },
    {
      'id': 4,
      'name': 'The Apprentice',
      'requirement': 25,
      'icon': 'hammer',
      'color': Colors.yellow,
      'description': 'Building strong habits. Well done!',
    },
    {
      'id': 5,
      'name': 'The Adept',
      'requirement': 50,
      'icon': 'zap',
      'color': Colors.orange,
      'description': 'You\'ve mastered the basics!',
    },
    {
      'id': 6,
      'name': 'The Disciplined',
      'requirement': 100,
      'icon': 'shield',
      'color': Colors.purple,
      'description': 'Discipline is your strength!',
    },
    {
      'id': 7,
      'name': 'The Specialist',
      'requirement': 250,
      'icon': 'award',
      'color': Colors.pink,
      'description': 'Specialized excellence achieved!',
    },
    {
      'id': 8,
      'name': 'The Expert',
      'requirement': 500,
      'icon': 'crown',
      'color': Colors.indigo,
      'description': 'True expertise unlocked!',
    },
    {
      'id': 9,
      'name': 'The Vanguard',
      'requirement': 1000,
      'icon': 'flame',
      'color': Colors.red,
      'description': 'Leading the way to greatness!',
    },
    {
      'id': 10,
      'name': 'The Sentinel',
      'requirement': 1750,
      'icon': 'eye',
      'color': Colors.cyan,
      'description': 'Watchful and unstoppable!',
    },
    {
      'id': 11,
      'name': 'The Virtuoso',
      'requirement': 2500,
      'icon': 'music',
      'color': Colors.teal,
      'description': 'Perfection in every task!',
    },
    {
      'id': 12,
      'name': 'The Master',
      'requirement': 4000,
      'icon': 'trophy',
      'color': Colors.amber,
      'description': 'Mastery achieved!',
    },
    {
      'id': 13,
      'name': 'The Grandmaster',
      'requirement': 6000,
      'icon': 'gem',
      'color': const Color(0xFF4CAF50),
      'description': 'Legendary prowess!',
    },
    {
      'id': 14,
      'name': 'The Titan',
      'requirement': 8000,
      'icon': 'mountain',
      'color': Colors.blueGrey,
      'description': 'Unshakable and mighty!',
    },
    {
      'id': 15,
      'name': 'The Luminary',
      'requirement': 10000,
      'icon': 'sun',
      'color': const Color(0xFFFFD700),
      'description': 'Shining beacon of excellence!',
    },
    {
      'id': 16,
      'name': 'The Ascended',
      'requirement': 10001,
      'icon': 'infinity',
      'color': const Color(0xFF9C27B0),
      'description': 'Beyond limits. Truly transcendent!',
      'animated': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final stats = await _firestoreService.getUserStatistics();
      final tasks = stats['completedTasks'] ?? 0;
      final tier = _firestoreService.getUserTier(tasks);

      // Find next tier
      Map<String, dynamic>? next;
      final currentTierId = tier['id'] as int;
      if (currentTierId < allTiers.length) {
        next = allTiers[currentTierId]; // Next tier (index = id because 0-based)
      }

      setState(() {
        completedTasks = tasks;
        currentTier = tier;
        nextTier = next;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

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
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: const Color(0xFF7C4DFF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildCurrentTierCard(),
                        _buildProgressSection(),
                        _buildAllTiersSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gradient = currentTier['gradient'] as List<dynamic>?;
    final Color headerColor = gradient != null && gradient.isNotEmpty
        ? gradient[0] as Color
        : const Color(0xFF7C4DFF);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient?.map((e) => e as Color).toList() ??
              [headerColor, headerColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your progress and milestones 🏆',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTierCard() {
    final tierIcon =
        _firestoreService.getIconFromString(currentTier['icon'] ?? 'sparkles');
    final gradient = currentTier['gradient'] as List<dynamic>?;
    final tierColor = currentTier['glow'] as Color? ?? const Color(0xFF7C4DFF);
    final isAnimated = currentTier['animated'] == true;

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: tierColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Current Tier',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: isAnimated ? _animation : const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: isAnimated ? _animation.value : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: gradient?.map((e) => e as Color).toList() ??
                              [tierColor, tierColor.withOpacity(0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withOpacity(isAnimated ? 0.6 : 0.4),
                            blurRadius: isAnimated ? 35 : 25,
                            spreadRadius: isAnimated ? 8 : 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(tierIcon, color: Colors.white, size: 60),
                          Positioned(
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'T${currentTier['id']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                currentTier['name'] ?? 'The Initiate',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                allTiers.firstWhere(
                  (t) => t['id'] == currentTier['id'],
                  orElse: () => allTiers[0],
                )['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient?.map((e) => (e as Color).withOpacity(0.2)).toList() ??
                        [tierColor.withOpacity(0.1), tierColor.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tierColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, color: tierColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$completedTasks Tasks Completed',
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (nextTier == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFFFA500).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                _firestoreService.getIconFromString('infinity'),
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Maximum Tier Reached!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ve achieved the ultimate status! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final nextTierRequirement = nextTier!['requirement'] as int;
    final tasksRemaining = nextTierRequirement - completedTasks;
    final progress = (completedTasks / nextTierRequirement).clamp(0.0, 1.0);
    final nextTierColor = nextTier!['color'] as Color;
    final nextTierIcon =
        _firestoreService.getIconFromString(nextTier!['icon']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nextTierColor,
                  ),
                  child: Icon(nextTierIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Tier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextTier!['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: nextTierColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedTasks / $nextTierRequirement',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: nextTierColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(nextTierColor),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nextTierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: nextTierColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, color: nextTierColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tasksRemaining > 0
                          ? 'Complete $tasksRemaining more ${tasksRemaining == 1 ? 'task' : 'tasks'} to unlock!'
                          : 'Ready to unlock!',
                      style: TextStyle(
                        color: nextTierColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTiersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Tiers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          ...allTiers.map((tier) {
            final isUnlocked = completedTasks >= (tier['requirement'] as int);
            final isCurrent = tier['id'] == currentTier['id'];
            final tierColor = tier['color'] as Color;
            final tierIcon = _firestoreService.getIconFromString(tier['icon']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? tierColor
                      : isUnlocked
                          ? tierColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: tierColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? tierColor : Colors.grey.shade300,
                  ),
                  child: Icon(
                    tierIcon,
                    color: isUnlocked ? Colors.white : Colors.grey.shade500,
                    size: 24,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tier['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? tierColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      tier['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isUnlocked ? Icons.check_circle : Icons.lock,
                          size: 14,
                          color: isUnlocked ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tier['requirement']} tasks required',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isUnlocked
                    ? Icon(Icons.check_circle, color: tierColor, size: 28)
                    : Icon(Icons.lock_outline,
                        color: Colors.grey.shade400, size: 28),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
