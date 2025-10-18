import 'package:demo/component/heatmap.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5), // Light purple
              Colors.white,
              Color(0xFFE3F2FD), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Gradient
                Container(
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
                        // Header Text
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
                              child: Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Profile Photo and Name
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
                                  child: GestureDetector(
                                    onTap: _authService.signOut,
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      backgroundImage: AssetImage("assets/images/dp.jpg"),
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
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
                                    'Alex Johnson',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '@alexj • Level 7 Achiever',
                                    style: TextStyle(
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
                  ),
                ),

                // Stats Card
                Transform.translate(
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
                                    value: '12',
                                    label: 'Streak',
                                    color: Color(0xFFFF6F00),
                                    bgColor: Color(0xFFFFF3E0),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.track_changes,
                                    value: '247',
                                    label: 'Tasks',
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
                                    value: '156',
                                    label: 'Hours',
                                    color: Color(0xFF4CAF50),
                                    bgColor: Color(0xFFE8F5E9),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.emoji_events,
                                    value: '8',
                                    label: 'Awards',
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
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Statistics',
                          icon: Icons.bar_chart,
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          onPressed: () {},
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
                          onPressed: () {},
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
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Heatmap Section
                Padding(
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
                              Icon(
                                Icons.calendar_today,
                                color: Color(0xFF7C4DFF),
                                size: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          const HeatMapPage(),
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
                ),

                SizedBox(height: 24),
              ],
            ),
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