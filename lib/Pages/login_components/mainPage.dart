import 'package:demo/Pages/login_components/authPage.dart';
import 'package:demo/Pages/ui_components/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Mainpage extends StatelessWidget {
  const Mainpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
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
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                ),
              ),
            );
          }

          // User is logged in -> show Navbar
          if (snapshot.hasData) {
            return Navbar();
          }

          // No user -> show AuthPage
          return Authpage();
        },
      ),
    );
  }
}
