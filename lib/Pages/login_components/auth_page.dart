import 'package:demo/Pages/login_components/login.dart';
import 'package:demo/Pages/login_components/regsiter.dart';
import 'package:flutter/material.dart';

class Authpage extends StatefulWidget {
  const Authpage({super.key});

  @override
  State<Authpage> createState() => _AuthpageState();
}

class _AuthpageState extends State<Authpage> {
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showRegisterPage: toggleScreens,);
    } else {
      return RegisterPage(showLoginPage: toggleScreens,);
    }
  }
}
