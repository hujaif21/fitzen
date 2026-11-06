import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import your SignIn screen
import 'home.dart'; // Import your Home dashboard

class FitZenSplashScreen extends StatefulWidget {
  const FitZenSplashScreen({super.key});

  @override
  State<FitZenSplashScreen> createState() => _FitZenSplashScreenState();
}

class _FitZenSplashScreenState extends State<FitZenSplashScreen> {
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6E6E6E);

  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    // 1. Wait for your logo animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    // 2. Check the saved session state
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // 3. Navigate with your custom fade transition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          // Route to Home if logged in, otherwise go to Login
          pageBuilder: (context, animation, secondaryAnimation) =>
          isLoggedIn ? const HomeScreen() : const FitZenSignInScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeIn,
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: child,
                  );
                },
                child: const Text(
                  "Build your strength. Find your balance",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 1.2,
                    fontFamily: 'Poppins',
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