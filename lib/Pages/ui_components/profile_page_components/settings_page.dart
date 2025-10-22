import 'package:demo/Pages/login_components/mainPage.dart';
import 'package:demo/Pages/ui_components/friend_components/friendListsPage.dart';
import 'package:demo/Pages/ui_components/profile_page_components/changePasswordPage.dart';
import 'package:demo/Pages/ui_components/profile_page_components/editUsernamePage.dart';
import 'package:demo/Pages/ui_components/profile_page_components/themeSelectionPage.dart';
import 'package:demo/component/achievements.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        elevation: 0,
      ),
      body: tierProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  tierProvider.primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSectionTitle('Account'),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Edit your profile information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditUsernamePage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Logout from your account',
                    onTap: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: tierProvider.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text('Sign Out?'),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: tierProvider.gradientColors,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const Mainpage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Preferences'),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notifications',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Appearance'),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.palette,
                    title: 'Theme',
                    subtitle: 'Customize your app theme',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSelectionPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('App Features'),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.people,
                    title: 'Friends',
                    subtitle: 'Manage friends & social features',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendsListPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.emoji_events,
                    title: 'Achievements',
                    subtitle: 'View unlocked badges & tiers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('App Info'),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version & info',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: tierProvider.gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.info,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('About'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Task Manager App',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'A productivity app to manage your tasks with friends and track your achievements.',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'FAQs and support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
    BuildContext context,
    TierThemeProvider tierProvider, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors
                  .map((c) => c.withOpacity(0.15))
                  .toList(),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tierProvider.primaryColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: tierProvider.primaryColor,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
