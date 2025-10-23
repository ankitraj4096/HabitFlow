import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditUsernamePage extends StatefulWidget {
  const EditUsernamePage({super.key});

  @override
  State<EditUsernamePage> createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final username = await _authService.getCurrentUsername();
      setState(() {
        _currentUsername = username;
        _usernameController.text = "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newUsername == _currentUsername) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.updateUsername(newUsername);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Username updated successfully!'),
              ],
            ),
            backgroundColor: context.read<TierThemeProvider>().primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

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
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tierProvider.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierProvider.glowColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Edit Username',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tierProvider.primaryColor,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Current Username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: tierProvider.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tierProvider.primaryColor
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_circle,
                                    color: tierProvider.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _currentUsername,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: tierProvider.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'New Username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _usernameController,
                              enabled: !_isSaving,
                              decoration: InputDecoration(
                                hintText: 'Enter new username',
                                prefixIcon: Icon(
                                  Icons.edit,
                                  color: tierProvider.primaryColor,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: tierProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your username will be visible to your friends',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Save Button
              Container(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierProvider.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: tierProvider.glowColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Username',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
}
