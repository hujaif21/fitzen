import 'dart:ui'; // Required for ImageFilter (Glassmorphism)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'home.dart';
import 'core_settings.dart'; // 🚨 Integrated for dynamic themes & AppColors
import 'network/api_manager.dart';

class FitZenSignInScreen extends StatefulWidget {
  final String? registeredEmail;

  const FitZenSignInScreen({super.key, this.registeredEmail});

  @override
  State<FitZenSignInScreen> createState() => _FitZenSignInScreenState();
}

class _FitZenSignInScreenState extends State<FitZenSignInScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  // --- Form Key & Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.registeredEmail != null) {
      _emailController.text = widget.registeredEmail!;
    }
    _passwordController.clear();
  }

  // --- Design System Tokens ---
  static const Color primaryOrange = Color(0xFFFF8A3D);
  static const Color primaryMagenta = Color(0xFFE91E8C);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, primaryMagenta],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = ApiManager().client;

      final credentials = {
        'action': 'login',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final response = await client.loginUser(credentials);

      if (!mounted) return;

      if (response.status == 'success') {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString(
          'userEmail',
          _emailController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Signed in successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network error: $error',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Stack(
            children: [
              // 1. Dynamic Aurora Mesh Background
              _buildAuroraBackground(context),

              // 2. Main Scrollable Form Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🚨 RESTORED ASSET LOGO WITH GRADIENT RING
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryMagenta.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: primaryMagenta, size: 36),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Gradient Wordmark
                        Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => primaryGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: const Text(
                              "FitZen",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Headlines
                        Center(
                          child: Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary(context),
                              letterSpacing: -0.5,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            "Strength + Balance starts here.",
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary(context),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Frosted Glass Form Container
                        _buildGlassCard(
                          context,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Input
                                _buildInputLabel(context, "Email Address"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  context,
                                  controller: _emailController,
                                  hint: "alex@example.com",
                                  icon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email address';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Password Input
                                _buildInputLabel(context, "Password"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  context,
                                  controller: _passwordController,
                                  hint: "••••••••",
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Primary CTA Button
                                Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryMagenta.withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                        : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Sign In",
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Footer Navigation
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FitZenRegisterScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary(context),
                                  fontFamily: 'Poppins',
                                ),
                                children: [
                                  const TextSpan(text: "New to FitZen? "),
                                  const TextSpan(
                                    text: "Create Account",
                                    style: TextStyle(
                                      color: primaryMagenta,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Aurora Mesh Background ---
  Widget _buildAuroraBackground(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0x20FF8A3D) : const Color(0x30FF8A3D),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0x2000ACC1) : const Color(0x3000ACC1),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  // --- Glassmorphic Container ---
  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardGlass(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border(context), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildInputLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary(context),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String hint,
        required IconData icon,
        bool isPassword = false,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword && _obscurePassword,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: const [],
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary(context),
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary(context), fontSize: 13.5),
        prefixIcon: Icon(icon, color: AppColors.textSecondary(context), size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary(context),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        )
            : null,
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryMagenta, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}