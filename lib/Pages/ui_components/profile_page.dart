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
  Map<String, int> heatmapData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load username
      final name = await _firestoreService.getUsername();
      
      // Load statistics
      final stats = await _firestoreService.getUserStatistics();
      
      setState(() {
        username = name;
        currentStreak = stats['currentStreak'];
        totalTasks = stats['totalTasks'];
        completedTasks = stats['completedTasks'];
        totalHours = stats['totalHours'];
        userLevel = _firestoreService.getUserLevel(completedTasks);
        heatmapData = stats['completionsByDate'];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5),
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: Color(0xFF7C4DFF),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildStatsCard(),
                        _buildActionButtons(context),
                        SizedBox(height: 24),
                        _buildHeatmapSection(),
                        SizedBox(height: 24),
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
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C4DFF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      await _authService.signOut();
                    },
                    child: Icon(
                      Icons.logout_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
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
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: TextStyle(
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
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '@${username.toLowerCase().replaceAll(' ', '')} • Level $userLevel Achiever',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Transform.translate(
      offset: Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Color(0xFF7C4DFF).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.local_fire_department,
                        value: currentStreak.toString(),
                        label: 'Day Streak',
                        color: Color(0xFFFF6F00),
                        bgColor: Color(0xFFFFF3E0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.track_changes,
                        value: completedTasks.toString(),
                        label: 'Done',
                        color: Color(0xFF2196F3),
                        bgColor: Color(0xFFE3F2FD),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.access_time,
                        value: totalHours.toString(),
                        label: 'Hours',
                        color: Color(0xFF4CAF50),
                        bgColor: Color(0xFFE8F5E9),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.assignment,
                        value: totalTasks.toString(),
                        label: 'Total',
                        color: Color(0xFFFFC107),
                        bgColor: Color(0xFFFFF8E1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Refresh',
              icon: Icons.refresh,
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              onPressed: _loadUserData,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Friends',
              icon: Icons.people,
              gradient: LinearGradient(
                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
              onPressed: () {
                // Navigate to friends page
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Settings',
              icon: Icons.settings,
              gradient: LinearGradient(
                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
              onPressed: () {
                // Navigate to settings
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Color(0xFF7C4DFF).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                        '$completedTasks completions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF7C4DFF),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              StreamBuilder<Map<String, int>>(
                stream: _firestoreService.getHeatmapData(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading heatmap',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? {};
                  return HeatMapPage(completionData: data);
                },
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 8),
                  ...List.generate(5, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(
                          36 * (index + 1),
                          76,
                          175,
                          80,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  SizedBox(width: 8),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
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
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
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
}
