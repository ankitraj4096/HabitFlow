import 'package:demo/component/heatmap.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FireStoreService _firestoreService = FireStoreService();

  String username = 'Loading...';
  int currentStreak = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int totalHours = 0;
  int userLevel = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final name = await _firestoreService.getUsername();
      final stats = await _firestoreService.getUserStatistics();

      setState(() {
        username = name;
        currentStreak = stats['currentStreak'];
        totalTasks = stats['totalTasks'];
        completedTasks = stats['completedTasks'];
        totalHours = stats['totalHours'];
        userLevel = _firestoreService.getUserLevel(completedTasks);
      });
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.3),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep building great habits! 🚀',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
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
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
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
                      '@${username.toLowerCase().replaceAll(' ', '')} • Level $userLevel Achiever',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
    IconData icon,
    String value,
    String label,
    Color color,
    Color bg,
  ) {
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
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
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
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              'Refresh',
              Icons.refresh,
              const [Color(0xFF667eea), Color(0xFF764ba2)],
              _loadUserData,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              'Friends',
              Icons.people,
              const [Color(0xFFf093fb), Color(0xFFf5576c)],
              () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              'Settings',
              Icons.settings,
              const [Color(0xFF4facfe), Color(0xFF00f2fe)],
              () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
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
          stream: _firestoreService.getHeatmapData(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text(
                  'Error loading heatmap',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                  ),
                ),
              );
            }

            final heatmapData = snap.data!;
            final totalCompletions = heatmapData.values.fold(0, (sum, count) => sum + count);

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
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF7C4DFF),
                          size: 20,
                        ),
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
                    Text(
                      'Less',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
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
                    Text(
                      'More',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
