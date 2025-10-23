import 'dart:async';
import 'package:demo/Pages/login_components/main_page.dart';
import 'package:demo/firebase_options.dart';
import 'package:demo/services/clean_up_service.dart';
import 'package:demo/services/notes/user_stats_provider.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Global timer for periodic cleanup
Timer? _cleanupTimer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize cleanup timer (runs every 24 hours)
  _initializeCleanupTimer();

  // ✅ Run app with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TierThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Initialize the periodic cleanup timer
void _initializeCleanupTimer() {
  // Cancel existing timer if any
  _cleanupTimer?.cancel();

  // Run cleanup every 24 hours
  _cleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cleanupService = CleanupService();
        debugPrint('🧹 Running scheduled cleanup...');
        await cleanupService.runFullCleanup(user.uid);
        debugPrint('✅ Scheduled cleanup completed');
      }
    } catch (e) {
      debugPrint('❌ Error during scheduled cleanup: $e');
    }
  });

  // Also run cleanup once on app start (with delay to not block startup)
  Future.delayed(const Duration(minutes: 2), () async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cleanupService = CleanupService();
        debugPrint('🧹 Running initial cleanup...');
        await cleanupService.runFullCleanup(user.uid);
        debugPrint('✅ Initial cleanup completed');
      }
    } catch (e) {
      debugPrint('❌ Error during initial cleanup: $e');
    }
  });

  debugPrint('✅ Cleanup timer initialized');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppInitializer(),
    );
  }
}

/// Widget that shows splash screen and initializes everything
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start timer for minimum 2 seconds splash
    final splashTimer = Future.delayed(const Duration(seconds: 2));

    try {
      // Wait for Firebase Auth to be ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Initialize tier theme provider (only if user is logged in)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        await context.read<TierThemeProvider>().initializeTierTheme();
        // UserStatsProvider will initialize automatically via its constructor
      }

      // Wait for the minimum splash duration to complete
      await splashTimer;
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Still wait for splash timer
      await splashTimer;
    } finally {
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      // Show splash screen for 2 seconds
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
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
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo/icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name or tagline
                  const Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 28,
                      color: Color(0xFF7C4DFF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Loading your experience...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // After 2 seconds, show the Mainpage
    return const Mainpage();
  }
}
