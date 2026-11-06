import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'profile.dart';
import 'core_settings.dart'; // 🚨 Integrated for dynamic themes & AppColors
import 'network/api_service.dart';
import 'models/HomeResponse.dart';
import 'add_food.dart';
import 'water.dart';
import 'progress.dart';
import 'bmi.dart';
import 'weight.dart';
import 'goals_streaks.dart';
import 'pedometer.dart';
import 'heart_rate.dart';
import 'diet_suggestions.dart';
import 'exercise_page.dart';
import 'dart:typed_data';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData? homeData;
  Uint8List? profileImageBytes;
  bool isLoading = true;
  bool isAddingWater = false;

  String? errorMessage;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? prefs.getString('email');

      if (email == null || email.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = 'User email not found. Please login again.';
        });
        return;
      }

      userEmail = email.trim();
      final savedImageBase64 = prefs.getString('profileImageBase64');
      if (savedImageBase64 != null && savedImageBase64.isNotEmpty) {
        profileImageBytes = base64Decode(savedImageBase64);
      } else {
        profileImageBytes = null;
      }

      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final date = '$day/$month/${now.year}';

      final response = await ApiService.getHomeData(userEmail, date);

      if (!mounted) return;

      if (response.status == 'success' && response.data != null) {
        setState(() {
          homeData = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = response.status == 'error'
              ? 'Unable to load your data.'
              : 'No home data available.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Something went wrong. Please try again.';
      });
      debugPrint('HOME ERROR: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FitZenSignInScreen()),
    );
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
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
                )
                    : errorMessage != null
                    ? _buildErrorState(context)
                    : Stack(
                  children: [
                    RefreshIndicator(
                      color: const Color(0xFFE91E8C),
                      backgroundColor: AppColors.card(context),
                      onRefresh: _loadHomeData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 24),
                            _buildHeroGreetingCard(context),
                            const SizedBox(height: 24),
                            _buildStreakCard(context),
                            const SizedBox(height: 24),
                            _buildNutritionCard(context),
                            const SizedBox(height: 32),
                            _buildQuickActions(context),
                            const SizedBox(height: 32),
                            _buildWaterCard(context),
                            const SizedBox(height: 32),
                            _buildMeals(context),
                            const SizedBox(height: 24),
                            _buildMindfulTip(context),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: _buildFloatingBottomNavigation(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Premium Aurora Mesh Gradient Background (Dark & Light Adaptive)
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

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: Color(0xFFE91E8C)),
            const SizedBox(height: 16),
            Text(
              'Unable to load your data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHomeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E8C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Try Again', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E8C).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FitZen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary(context),
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'HEALTH SUITE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary(context),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            if (mounted) _loadHomeData();
          },
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(color: AppColors.card(context), shape: BoxShape.circle),
              child: profileImageBytes != null
                  ? ClipOval(
                child: Image.memory(
                  profileImageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Color(0xFFE91E8C), size: 22),
                ),
              )
                  : const Icon(Icons.person_rounded, color: Color(0xFFE91E8C), size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _logout,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.logout_rounded, color: AppColors.textSecondary(context), size: 19),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroGreetingCard(BuildContext context) {
    final name = homeData?.name ?? 'User';
    final now = DateTime.now();
    final hour = now.hour;

    String timeGreeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    IconData timeIcon = hour < 12 ? Icons.wb_sunny_rounded : (hour < 17 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E8C).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white.withOpacity(0.2), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(timeIcon, color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              timeGreeting,
                              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to hit your health goals today?',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(22), Color? shadowColor}) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04)),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.cardGlass(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border(context), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final streak = homeData?.streak ?? 0;
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsStreaksPage())),
      child: _buildGlassCard(
        context,
        shadowColor: const Color(0xFFFF8A3D).withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark ? [const Color(0xFF3A231C), const Color(0xFF2C1914)] : [const Color(0xFFFFF3EB), const Color(0xFFFFE8D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF8A3D).withOpacity(0.35)),
              ),
              child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$streak Day Streak',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: -0.3, fontFamily: 'Poppins'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF059669), fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consistency is key.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary(context), size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context) {
    final calories = homeData?.caloriesConsumed ?? 0;
    final target = homeData?.calorieTarget ?? 0;
    final remaining = math.max(0, target - calories);
    final progress = target > 0 ? (calories / target).clamp(0.0, 1.0) : 0.0;

    return _buildGlassCard(
      context,
      shadowColor: const Color(0xFFE91E8C).withOpacity(0.12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.25)),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFFE91E8C), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Today's Nutrition",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  'Target: ${target.toInt()}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context), fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 180,
            child: _CaloriesCircle(consumed: calories.toDouble(), progress: progress),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E8C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFE91E8C)),
                const SizedBox(width: 6),
                Text(
                  '${remaining.toInt()} kcal remaining',
                  style: const TextStyle(color: Color(0xFFE91E8C), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _MacroCard(context, title: 'Protein', value: '${homeData?.proteinConsumed.toInt() ?? 0}', target: '${homeData?.proteinTarget.toInt() ?? 0}g', gradient: const [Color(0xFFFF5376), Color(0xFFE91E8C)], accentColor: const Color(0xFFE91E8C), progress: _progress(homeData?.proteinConsumed, homeData?.proteinTarget))),
              const SizedBox(width: 8),
              Expanded(child: _MacroCard(context, title: 'Carbs', value: '${homeData?.carbsConsumed.toInt() ?? 0}', target: '${homeData?.carbsTarget.toInt() ?? 0}g', gradient: const [Color(0xFFFFB259), Color(0xFFFF8A3D)], accentColor: const Color(0xFFFF8A3D), progress: _progress(homeData?.carbsConsumed, homeData?.carbsTarget))),
              const SizedBox(width: 8),
              Expanded(child: _MacroCard(context, title: 'Fat', value: '${homeData?.fatConsumed.toInt() ?? 0}', target: '${homeData?.fatTarget.toInt() ?? 0}g', gradient: const [Color(0xFF34D399), Color(0xFF10B981)], accentColor: const Color(0xFF10B981), progress: _progress(homeData?.fatConsumed, homeData?.fatTarget))),
            ],
          ),
        ],
      ),
    );
  }

  double _progress(num? value, num? target) {
    if (value == null || target == null || target == 0) return 0;
    return (value / target).clamp(0.0, 1.0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
            ),
            const Spacer(),
            Text(
              'Scroll for more →',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _actionItem(context, icon: Icons.restaurant_rounded, label: 'Food', gradient: const [Color(0xFFFF6B81), Color(0xFFE91E8C)], onTap: () async { if (userEmail.isEmpty) return; await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFoodPage(email: userEmail))); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.water_drop_rounded, label: 'Water', gradient: const [Color(0xFF26C6DA), Color(0xFF008B87)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => WaterPage(email: userEmail, waterGoalML: homeData?.waterGoalML.toDouble() ?? 2500))); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.monitor_weight_rounded, label: 'Weight', gradient: const [Color(0xFF34D399), Color(0xFF059669)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightPage())); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.calculate_rounded, label: 'BMI', gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const BMIPage())); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.directions_walk_rounded, label: 'Steps', gradient: const [Color(0xFFFFB259), Color(0xFFFF8A3D)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const PedometerScreen())); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.monitor_heart_rounded, label: 'Pulse', gradient: const [Color(0xFFFB7185), Color(0xFFE11D48)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const HeartRateScreen())); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.restaurant_menu_rounded, label: 'Diet Plan', gradient: const [Color(0xFF2DD4BF), Color(0xFF0D9488)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const DietSuggestionsScreen())); if (mounted) _loadHomeData(); }),
                const SizedBox(width: 12),
                _actionItem(context, icon: Icons.fitness_center_rounded, label: 'Workout', gradient: const [Color(0xFFFF8A3D), Color(0xFFEA580C)], onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisePage())); if (mounted) _loadHomeData(); }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionItem(BuildContext context, {required IconData icon, required String label, required List<Color> gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 82,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.cardGlass(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context), width: 1.2),
              boxShadow: [
                BoxShadow(color: gradient[1].withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: gradient[1].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gradient[1].withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: gradient[1], size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterCard(BuildContext context) {
    final double water = homeData?.waterML.toDouble() ?? 0;
    final double goal = homeData?.waterGoalML.toDouble() ?? 2500;
    final double progress = goal > 0 ? (water / goal).clamp(0.0, 1.0) : 0.0;
    final isDark = AppColors.isDark(context);

    return _buildGlassCard(
      context,
      shadowColor: const Color(0xFF008B87).withOpacity(0.12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00363A) : const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00ACC1).withOpacity(0.3)),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF00ACC1), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Water", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: -0.2, fontFamily: 'Poppins')),
                    Text('Daily Goal: ${(goal / 1000).toStringAsFixed(1)} L', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)]).createShader(bounds),
                    child: Text('${(water / 1000).toStringAsFixed(1)} L', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  ),
                  Text('${(progress * 100).toInt()}% target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context), fontFamily: 'Poppins')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)]))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => WaterPage(email: userEmail, waterGoalML: homeData?.waterGoalML.toDouble() ?? 2500)));
                  if (mounted) _loadHomeData();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Log Water', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Meals",
              style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text('4 planned', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context), fontFamily: 'Poppins')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MealTile(context, icon: Icons.wb_sunny_rounded, iconGradient: const [Color(0xFFFFB259), Color(0xFFFF8A3D)], title: 'Breakfast', status: homeData?.breakfast ?? 'Not Complete', subtitle: homeData?.breakfastFoods ?? ''),
        _MealTile(context, icon: Icons.lunch_dining_rounded, iconGradient: const [Color(0xFFFF7E8B), Color(0xFFE91E8C)], title: 'Lunch', status: homeData?.lunch ?? 'Not Complete', subtitle: homeData?.lunchFoods ?? ''),
        _MealTile(context, icon: Icons.apple_rounded, iconGradient: const [Color(0xFF34D399), Color(0xFF10B981)], title: 'Snack', status: homeData?.snack ?? 'Not Complete', subtitle: homeData?.snackFoods ?? ''),
        _MealTile(context, icon: Icons.nights_stay_rounded, iconGradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)], title: 'Dinner', status: homeData?.dinner ?? 'Not Complete', subtitle: homeData?.dinnerFoods ?? ''),
      ],
    );
  }

  Widget _buildMindfulTip(BuildContext context) {
    return _buildGlassCard(
      context,
      shadowColor: const Color(0xFFFF8A3D).withOpacity(0.08),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFFFA000)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFF8A3D).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mindful Eating Tip', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context), fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(
                  'Slow down and enjoy your meals. Eating mindfully helps your body recognize fullness naturally.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary(context), fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNavigation(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.cardGlass(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border(context), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressPage())),
                child: const _NavItem(icon: Icons.trending_up_rounded, label: 'Progress'),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                  if (mounted) _loadHomeData();
                },
                child: const _NavItem(icon: Icons.person_rounded, label: 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaloriesCircle extends StatelessWidget {
  final double consumed;
  final double progress;

  const _CaloriesCircle({required this.consumed, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CaloriesPainter(progress: progress, context: context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E8C).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE91E8C), size: 22),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                consumed.toInt().toString(),
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
              ),
            ),
            Text(
              'Consumed (kcal)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context), fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaloriesPainter extends CustomPainter {
  final double progress;
  final BuildContext context;

  _CaloriesPainter({required this.progress, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    final backgroundPaint = Paint()
      ..color = AppColors.isDark(context) ? const Color(0xFF334155) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      // FIXED SYNTAX ERROR HERE
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CaloriesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _MacroCard extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String value;
  final String target;
  final double progress;
  final List<Color> gradient;
  final Color accentColor;

  const _MacroCard(this.context, {required this.title, required this.value, required this.target, required this.progress, required this.gradient, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context), fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: gradient))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: value, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  TextSpan(text: '/$target', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String status;
  final String subtitle;

  const _MealTile(this.context, {required this.icon, required this.iconGradient, required this.title, required this.status, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    final completed = status.toLowerCase() == 'complete';
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardGlass(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconGradient[1].withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: iconGradient[1].withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconGradient[1], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context), fontFamily: 'Poppins')),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context), fontFamily: 'Poppins')),
                ]
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: completed ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE9F7EE)) : AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: completed ? const Color(0xFF10B981).withOpacity(0.4) : AppColors.border(context)),
            ),
            child: Text(
              completed ? '✓ Done' : 'Pending',
              style: TextStyle(color: completed ? const Color(0xFF34D399) : AppColors.textSecondary(context), fontSize: 10.5, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFE91E8C);
    final inactiveColor = AppColors.textSecondary(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (active)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🚨 REMOVED 'const' BECAUSE 'icon' IS A VARIABLE
                Icon(icon, color: activeColor, size: 20),
                const SizedBox(width: 6),
                // 🚨 REMOVED 'const' BECAUSE 'label' IS A VARIABLE
                Text(
                  label,
                  style: const TextStyle(
                    color: activeColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else ...[
          // 🚨 REMOVED 'const' BECAUSE 'icon' IS A VARIABLE
          Icon(icon, color: inactiveColor, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: inactiveColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}