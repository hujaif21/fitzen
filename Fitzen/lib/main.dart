import 'package:flutter/material.dart';
import 'core_settings.dart'; // 🚨 Added for dynamic theme support
import 'splash.dart';

void main() {
  runApp(const FitZenApp());
}

class FitZenApp extends StatelessWidget {
  const FitZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚨 This builder listens to the Dark Mode switch in Settings
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'FitZen',
          debugShowCheckedModeBanner: false,

          // Connects to your global theme state
          themeMode: currentThemeMode,

          // Light Mode Theme
          theme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            brightness: Brightness.light,
          ),

          // Dark Mode Theme
          darkTheme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFF121212),
            brightness: Brightness.dark,
          ),

          home: const FitZenSplashScreen(),
        );
      },
    );
  }
}