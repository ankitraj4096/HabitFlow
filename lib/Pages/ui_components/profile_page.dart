import 'package:demo/Pages/ui_components/friendTasksManager.dart';
import 'package:demo/Pages/ui_components/settings_page.dart';
import 'package:demo/component/heatmap.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String? viewingUserID;
  final String? viewingUsername;
  final bool isOwnProfile; 

  ProfilePage({super.key, this.viewingUserID, this.viewingUsername})
      : isOwnProfile = viewingUserID == null;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FireStoreService _firestoreService = FireStoreService();

  String username = 'Loading...';
  int currentStreak = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int totalHours = 0;
  Map<String, dynamic> userTier = {};
  bool isLoading = true;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final String name;
      final Map<String, dynamic> stats;

      if (widget.isOwnProfile) {
        name = await _firestoreService.getUsername();
        stats = await _firestoreService.getUserStatistics();
      } else {
        name = widget.viewingUsername ?? 'User';
        stats = await _firestoreService.getUserStatisticsForUser(
          widget.viewingUserID!,
        );
      }

      if (mounted) {
        setState(() {
          username = name;
          currentStreak = stats['currentStreak'];
          totalTasks = stats['totalTasks'];
          completedTasks = stats['completedTasks'];
          totalHours = stats['totalHours'];
          userTier = _firestoreService.getUserTier(completedTasks);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          top: true,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C4DFF),
                    ),
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
                        _buildStatsCard(),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildHeatmapSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gradientColors = (userTier['gradient'] as List<dynamic>?)
            ?.map((e) => e as Color)
            .toList() ??
        [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
    final glowColor = userTier['glow'] as Color? ?? const Color(0xFF7C4DFF);
    final tierIcon = _firestoreService.getIconFromString(
      userTier['icon'] ?? 'sparkles',
    );
    final isAnimated = userTier['animated'] == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isOwnProfile
                        ? 'Your Profile'
                        : '$username\'s Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isOwnProfile
                        ? 'Keep building great habits! 🚀'
                        : 'View their progress',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (widget.isOwnProfile)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: GestureDetector(
                    onTap: () async => await _authService.signOut(),
                    child: const Icon(
                      Icons.logout_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradientColors),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(
                            isAnimated ? _glowAnimation.value : 0.5,
                          ),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(tierIcon, color: Colors.white, size: 36),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Text(
                              "T${userTier['id'] ?? 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${username.toLowerCase().replaceAll(' ', '')}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tierIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              userTier['name'] ?? 'The Initiate',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatsCard() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statItem(
                      Icons.local_fire_department,
                      '$currentStreak',
                      'Day Streak',
                      const Color(0xFFFF6F00),
                      const Color(0xFFFFF3E0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statItem(
                      Icons.track_changes,
                      '$completedTasks',
                      'Done',
                      const Color(0xFF2196F3),
                      const Color(0xFFE3F2FD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statItem(
                      Icons.access_time,
                      '$totalHours',
                      'Hours',
                      const Color(0xFF4CAF50),
                      const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statItem(
                      Icons.assignment,
                      '$totalTasks',
                      'Total',
                      const Color(0xFFFFC107),
                      const Color(0xFFFFF8E1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // *** THIS IS THE CORRECTED METHOD ***
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              'Friends',
              Icons.people,
              const [Color(0xFFf093fb), Color(0xFFf5576c)],
              () {
                // Navigate to Friends page (future implementation)
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionBtn(
              widget.isOwnProfile ? 'Settings' : 'Tasks',
              widget.isOwnProfile ? Icons.settings : Icons.task_alt,
              const [Color(0xFF4facfe), Color(0xFF00f2fe)],
              () {
                if (widget.isOwnProfile) {
                  // Navigate to the user's own settings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                } else {
                  // Navigate to the friend's task manager page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendTasksManagerPage(
                        friendUserID: widget.viewingUserID!,
                        friendUsername: widget.viewingUsername ?? 'Friend',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF7C4DFF).withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<Map<String, int>>(
          stream: widget.isOwnProfile
              ? _firestoreService.getHeatmapData()
              : _firestoreService.getHeatmapDataForUser(widget.viewingUserID!),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                  child: Text('Error loading heatmap',
                      style: TextStyle(color: Colors.red)));
            }
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C4DFF),
                    ),
                  ),
                ),
              );
            }
            final heatmapData = snap.data!;
            final totalCompletions = heatmapData.values.fold(
              0,
              (sum, count) => sum + count,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Activity Heatmap',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$totalCompletions completions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF7C4DFF), size: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HeatMapPage(completionData: heatmapData),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Less',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(76, 175, 80, (i + 1) * 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('More',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 50,)
              ],
            );
          },
        ),
      ),
    );
  }
}
