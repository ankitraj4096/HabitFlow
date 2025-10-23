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
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium "H" Logo - matching login page
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow circle
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                        // Main logo container
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFF5F5F5),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
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
                                  fontSize: 70,
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
                          top: 20,
                          left: 35,
                          child: Container(
                            width: 30,
                            height: 30,
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
                  ),
                  const SizedBox(height: 40),


                  // App name and tagline - matching login page style
                  const Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),


                  Text(
                    'Build Better Habits',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 50),


                  // Loading indicator - matching login page colors
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 3.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
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
