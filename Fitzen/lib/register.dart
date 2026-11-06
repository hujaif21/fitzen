import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'login.dart';
import 'core_settings.dart'; // 🚨 Integrated for dynamic themes & AppColors
import 'network/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitZenRegisterScreen extends StatefulWidget {
  const FitZenRegisterScreen({super.key});

  @override
  State<FitZenRegisterScreen> createState() => _FitZenRegisterScreenState();
}

class _FitZenRegisterScreenState extends State<FitZenRegisterScreen> {
  int _currentStep = 1;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _selectedGender;
  String? _genderError;
  String? _selectedGoal;

  final List<String> _goals = [
    'Gain Weight',
    'Lose Weight',
    'Build Muscle',
  ];

  static const Color primaryOrange = Color(0xFFFF8A3D);
  static const Color primaryMagenta = Color(0xFFE91E8C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    if (_isLoading) return;
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary(context),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryMagenta),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
        '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _genderError = _selectedGender == null ? 'Please select your gender' : null;
    });

    final bool isFormValid = _formKeyStep2.currentState?.validate() ?? false;
    if (!isFormValid || _selectedGender == null) return;

    setState(() => _isLoading = true);

    try {
      final client = ApiManager().client;

      final registerData = {
        'action': 'register',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'name': _fullNameController.text.trim(),
      };

      final registerResponse = await client.loginUser(registerData);
      if (!mounted) return;

      if (registerResponse.status != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(registerResponse.message, style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final double weight = double.tryParse(_weightController.text.trim()) ?? 0;
      final double height = double.tryParse(_heightController.text.trim()) ?? 0;

      final profileData = {
        'action': 'saveProfile',
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'dob': _dobController.text.trim(),
        'weight': weight,
        'height': height,
        'goal': _selectedGoal,
      };

      final profileResponse = await client.loginUser(profileData);
      if (!mounted) return;

      if (profileResponse.status != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileResponse.message, style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', _emailController.text.trim());
      await prefs.setString('savedUserName', _fullNameController.text.trim());
      await prefs.setString('userHeight', _heightController.text.trim());
      await prefs.setDouble('userWeight', weight);
      if (_selectedGoal != null) {
        await prefs.setString('userGoal', _selectedGoal!);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => FitZenSignInScreen(
            registeredEmail: _emailController.text.trim(),
          ),
        ),
            (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $error', style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

              // 2. Main Content inside SafeArea
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP BAR & PROGRESS WIDGET
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary(context), size: 20),
                              onPressed: _handleBackButton,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStepDot(context, 1, 'Account'),
                              Container(width: 20, height: 2, color: _currentStep == 2 ? primaryOrange : AppColors.border(context)),
                              _buildStepDot(context, 2, 'Profile'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // HERO HEADER CARD
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryMagenta.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentStep == 1 ? 'Join FitZen Today!' : 'Almost There! 🎯',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins'),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _currentStep == 1 ? 'Create your credentials to get started.' : 'Tell us your metrics for custom insights.',
                                    style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.9), fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // FROSTED GLASS FORM CONTAINER
                      _buildGlassCard(
                        context,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 1 ? _buildStep1(context) : _buildStep2(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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
            padding: const EdgeInsets.all(22),
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

  Widget _buildStepDot(BuildContext context, int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? primaryOrange.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: isActive ? primaryGradient : null,
              color: isActive ? null : AppColors.card(context),
              border: isActive ? null : Border.all(color: AppColors.border(context), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isCurrent ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputLabel(context, 'Full Name'),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            controller: _fullNameController,
            hint: 'Alex Morgan',
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your full name';
              if (value.trim().length < 2) return 'Please enter a valid name';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildInputLabel(context, 'Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            controller: _emailController,
            hint: 'alex@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email address';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildInputLabel(context, 'Password'),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 32),
          _buildGradientButton(
            text: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (_formKeyStep1.currentState?.validate() ?? false) {
                setState(() => _currentStep = 2);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputLabel(context, 'Gender'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildGenderOption(context, 'Male', Icons.male_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildGenderOption(context, 'Female', Icons.female_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildGenderOption(context, 'Others', Icons.transgender_rounded)),
            ],
          ),
          if (_genderError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_genderError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'Poppins')),
            ),
          ],
          const SizedBox(height: 18),
          _buildInputLabel(context, 'Date of Birth'),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            controller: _dobController,
            hint: 'DD/MM/YYYY',
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (value) => value == null || value.isEmpty ? 'Please select your date of birth' : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(context, 'Weight (kg)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      context,
                      controller: _weightController,
                      hint: 'e.g. 75',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final weight = double.tryParse(value.trim());
                        if (weight == null || weight <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(context, 'Height (cm)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      context,
                      controller: _heightController,
                      hint: 'e.g. 175',
                      icon: Icons.straighten,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final height = double.tryParse(value.trim());
                        if (height == null || height <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInputLabel(context, 'Primary Goal'),
          const SizedBox(height: 8),
          _buildDropdownField(context, hint: 'Select your main goal', icon: Icons.track_changes_outlined),
          const SizedBox(height: 32),
          _buildGradientButton(
            text: 'Create Account',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary(context),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String label, IconData icon) {
    final bool isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() { _selectedGender = label; _genderError = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withOpacity(0.12) : AppColors.card(context),
          border: Border.all(
            color: isSelected ? primaryOrange : (_genderError != null ? Colors.redAccent : AppColors.border(context)),
            width: isSelected ? 2 : 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? primaryOrange : AppColors.textSecondary(context), size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryOrange : AppColors.textPrimary(context),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, {required String hint, required IconData icon}) {
    return DropdownButtonFormField<String>(
      value: _selectedGoal,
      validator: (value) => value == null ? 'Please select your primary goal' : null,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary(context)),
      style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
      dropdownColor: AppColors.card(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary(context), fontSize: 13.5, fontFamily: 'Poppins'),
        prefixIcon: Icon(icon, color: AppColors.textSecondary(context), size: 22),
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border(context), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryOrange, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
      items: _goals.map((String goal) {
        return DropdownMenuItem<String>(
          value: goal,
          child: Text(goal, style: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary(context))),
        );
      }).toList(),
      onChanged: _isLoading ? null : (String? newValue) => setState(() => _selectedGoal = newValue),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required String hint,
        required IconData icon,
        bool isPassword = false,
        TextEditingController? controller,
        bool readOnly = false,
        VoidCallback? onTap,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: isPassword && _obscurePassword,
      style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary(context), fontSize: 13.5, fontFamily: 'Poppins'),
        prefixIcon: Icon(icon, color: AppColors.textSecondary(context), size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary(context),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border(context), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryOrange, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback? onPressed, IconData? icon, bool isLoading = false}) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: onPressed == null ? const LinearGradient(colors: [Colors.grey, Colors.grey]) : primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? []
            : [
          BoxShadow(
            color: primaryMagenta.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: Colors.white, size: 18)],
          ],
        ),
      ),
    );
  }
}