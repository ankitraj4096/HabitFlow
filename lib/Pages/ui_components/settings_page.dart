import 'package:demo/Pages/login_components/mainPage.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final AuthService _authService = AuthService();
  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSectionTitle('Account'),
            _buildListTile(
              context,
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Edit your profile information',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Logout from your account',
              onTap: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const Mainpage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            _buildListTile(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage notifications',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('App Features'),
            _buildListTile(
              context,
              icon: Icons.people,
              title: 'Friends',
              subtitle: 'Manage friends & social features',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.task_alt,
              title: 'Tasks',
              subtitle: 'Manage your tasks & habits',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.emoji_events,
              title: 'Achievements',
              subtitle: 'View unlocked badges & tiers',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('App Info'),
            _buildListTile(
              context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version & info',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQs and support',
              onTap: () {},
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
