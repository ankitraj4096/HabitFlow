import 'package:demo/Pages/login_components/mainPage.dart';
import 'package:demo/Pages/ui_components/friend_components/friendListsPage.dart';
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
                    onTap: () => _showEditUsernameDialog(context, tierProvider),
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () =>
                        _showChangePasswordDialog(context, tierProvider),
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Logout from your account',
                    onTap: () async {
                      await _authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const Mainpage(),
                          ),
                          (Route<dynamic> route) => false,
                        );
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
                    onTap: () {},
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
                    onTap: () {},
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () {},
                  ),
                  _buildListTile(
                    context,
                    tierProvider,
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

  // Edit Username Dialog
  void _showEditUsernameDialog(
    BuildContext context,
    TierThemeProvider tierProvider,
  ) async {
    final TextEditingController usernameController = TextEditingController();
    bool isLoading = false;

    final currentUsername = await _authService.getCurrentUsername();
    usernameController.text = currentUsername;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors
                        .map((c) => c.withOpacity(0.2))
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: tierProvider.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text('Edit Username'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your new username',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: tierProvider.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tierProvider.primaryColor,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(color: tierProvider.primaryColor),
                ),
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tierProvider.gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final newUsername = usernameController.text.trim();

                        if (newUsername.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username cannot be empty'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (newUsername == currentUsername) {
                          Navigator.pop(context);
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          await _authService.updateUsername(newUsername);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Username updated successfully!',
                                    ),
                                  ],
                                ),
                                backgroundColor: tierProvider.primaryColor,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Change Password Dialog
  void _showChangePasswordDialog(
    BuildContext context,
    TierThemeProvider tierProvider,
  ) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors
                        .map((c) => c.withOpacity(0.2))
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: tierProvider.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For your security, please enter your current password',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: tierProvider.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: tierProvider.primaryColor,
                      ),
                      onPressed: () {
                        setState(
                          () => showCurrentPassword = !showCurrentPassword,
                        );
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: tierProvider.primaryColor),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(
                      Icons.lock_reset,
                      color: tierProvider.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: tierProvider.primaryColor,
                      ),
                      onPressed: () {
                        setState(() => showNewPassword = !showNewPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: tierProvider.primaryColor),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(
                      Icons.check_circle_outline,
                      color: tierProvider.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: tierProvider.primaryColor,
                      ),
                      onPressed: () {
                        setState(
                          () => showConfirmPassword = !showConfirmPassword,
                        );
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: tierProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: tierProvider.primaryColor),
                  ),
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tierProvider.gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final currentPassword = currentPasswordController.text
                            .trim();
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword = confirmPasswordController.text
                            .trim();

                        if (currentPassword.isEmpty ||
                            newPassword.isEmpty ||
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All fields are required'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (currentPassword == newPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'New password must be different from current password',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New passwords do not match'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (newPassword.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password must be at least 6 characters',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          await _authService.changePassword(
                            currentPassword,
                            newPassword,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Password changed successfully!',
                                    ),
                                  ],
                                ),
                                backgroundColor: tierProvider.primaryColor,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
