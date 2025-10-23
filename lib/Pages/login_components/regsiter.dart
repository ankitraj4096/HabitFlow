import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/component/error_dialog.dart';
import 'package:demo/component/textfield.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController emailController;
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Username validation
  String? usernameError;
  String? usernameSuccess;
  bool isCheckingUsername = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Listen to username changes
    usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final username = usernameController.text.trim();

    // Reset states
    setState(() {
      usernameError = null;
      usernameSuccess = null;
      isCheckingUsername = false;
    });

    // Don't check if empty or too short
    if (username.isEmpty || username.length < 3) {
      return;
    }

    // Check format first
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() {
        usernameError = 'Only letters, numbers, and underscores allowed';
      });
      return;
    }

    // Show checking indicator
    setState(() => isCheckingUsername = true);

    // Debounce the API call
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          if (query.docs.isNotEmpty) {
            usernameError = 'Username already taken';
            usernameSuccess = null;
          } else {
            usernameError = null;
            usernameSuccess = 'Username available!';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          usernameError = null;
          usernameSuccess = null;
        });
      }
      debugPrint('Error checking username: $e');
    }
  }

  Future<void> signUp() async {
    final authService = AuthService();

    // Validation
    if (usernameController.text.trim().isEmpty) {
      ErrorDialog.show(context, message: 'Please enter a username');
      return;
    }

    if (usernameError != null) {
      ErrorDialog.show(context, message: usernameError!);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      ErrorDialog.show(context, message: 'Please enter an email address');
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      ErrorDialog.show(context, message: 'Please enter a password');
      return;
    }

    if (confirmPasswordController.text.trim().isEmpty) {
      ErrorDialog.show(context, message: 'Please confirm your password');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ErrorDialog.show(context, message: "Passwords don't match!");
      return;
    }

    try {
      await authService.signUpWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
      );

      // Success! The auth state listener will automatically navigate to home page
    } catch (e) {
      // Show error only
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ErrorDialog.show(context, message: errorMessage);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium "H" Logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow circle
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFF667eea,
                                  ).withValues(alpha: 0.3),
                                  const Color(
                                    0xFF764ba2,
                                  ).withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                          // Main logo container
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                        Color(0xFFf093fb),
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  'H',
                                  style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                    fontFamily: 'Sans-serif',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Inner highlight
                          Positioned(
                            top: 12,
                            left: 20,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.8),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // App Title
                      const Text(
                        "Build Better",
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Join us and start building",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Register Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            children: [
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Color(0xFF667eea),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign up to get started',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Username field with validation
                              MyTextField(
                                controller: usernameController,
                                hintText: "Username",
                                obscureText: false,
                              ),
                              // Username validation feedback
                              if (isCheckingUsername)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.grey[600]!,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Checking availability...',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (usernameError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        usernameError!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (usernameSuccess != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        usernameSuccess!,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),

                              MyTextField(
                                controller: emailController,
                                hintText: "Email Address",
                                obscureText: false,
                              ),
                              const SizedBox(height: 12),

                              MyTextField(
                                controller: passwordController,
                                hintText: 'Password',
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),

                              MyTextField(
                                controller: confirmPasswordController,
                                hintText: 'Confirm Password',
                                obscureText: true,
                              ),
                              const SizedBox(height: 20),

                              // Sign Up Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF667eea,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: signUp,
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Login Link
                              GestureDetector(
                                onTap: widget.showLoginPage,
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: "Sign In",
                                        style: TextStyle(
                                          color: Color(0xFF667eea),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
