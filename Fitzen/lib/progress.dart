import 'dart:ui'; // Required for Glassmorphism ImageFilter
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'network/api_service.dart';
import 'profile.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int selectedPeriod = 0; // 0: 7 Days, 1: 30 Days, 2: 90 Days
  bool isLoading = true;

  // ============================================================
  // DYNAMIC DATA
  // ============================================================
  double currentWeight = 0.0;
  double startingWeight = 0.0;
  double goalWeight = 55.0;

  int caloriesTarget = 2000;
  int caloriesAverage = 0;

  double waterTarget = 2.5;
  double waterAverage = 0.0;

  int proteinTarget = 100;
  int proteinAverage = 0;

  int currentStreak = 0;
  List<Map<String, dynamic>> weeklyActivity = [];

  @override
  void initState() {
    super.initState();
    _loadProgressData(7); // Default to 7 days
  }

  Future<void> _loadProgressData(int days) async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      if (userEmail.isNotEmpty) {
        final response = await ApiService.getProgress(userEmail, period: days);

        if (response['status'] == 'success') {
          final data = response['data'] ?? {};
          setState(() {
            currentWeight = (data['currentWeight'] as num?)?.toDouble() ?? 0.0;
            startingWeight = (data['startingWeight'] as num?)?.toDouble() ?? 0.0;
            goalWeight = (data['goalWeight'] as num?)?.toDouble() ?? 55.0;

            caloriesTarget = (data['caloriesTarget'] as num?)?.toInt() ?? 2000;
            caloriesAverage = (data['caloriesAverage'] as num?)?.toInt() ?? 0;

            proteinTarget = (data['proteinTarget'] as num?)?.toInt() ?? 100;
            proteinAverage = (data['proteinAverage'] as num?)?.toInt() ?? 0;

            waterTarget = (data['waterTarget'] as num?)?.toDouble() ?? 2.5;
            waterAverage = (data['waterAverage'] as num?)?.toDouble() ?? 0.0;

            currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;

            final rawActivity = data['weeklyActivity'] as List<dynamic>? ?? [];
            weeklyActivity = rawActivity.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. FitZen Bioluminescent Aurora Mesh Background
          _buildAuroraBackground(),

          // 2. Main Page Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isLoading
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E8C).withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            color: Color(0xFFE91E8C),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Analyzing Progress Metrics...",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 16),
                        _buildProgressOverview(),
                        const SizedBox(height: 18),
                        _buildWeightProgress(),
                        const SizedBox(height: 18),
                        _buildNutritionAnalytics(),
                        const SizedBox(height: 18),
                        _buildWaterProgress(),
                        const SizedBox(height: 18),
                        _buildWeeklyActivity(),
                        const SizedBox(height: 18),
                        _buildStreakCard(),
                        const SizedBox(height: 18),
                        _buildInsightCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UI GLASS & AURORA HELPERS
  // ============================================================

  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 340,
            height: 340,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x30FF8A3D),
            ),
          ),
        ),
        Positioned(
          top: 220,
          left: -110,
          child: Container(
            width: 380,
            height: 380,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x28E91E8C),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -90,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x2000ACC1),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: br,
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FitZen Progress',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Analytics & Trajectory',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF0F172A), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERIOD SELECTOR
  // ============================================================
  Widget _buildPeriodSelector() {
    final periods = ['7 Days', '30 Days', '90 Days'];
    final periodDays = [7, 30, 90];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: List.generate(
          periods.length,
              (index) {
            final selected = selectedPeriod == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (selectedPeriod != index) {
                    setState(() => selectedPeriod = index);
                    _loadProgressData(periodDays[index]);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                    )
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: const Color(0xFFE91E8C).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      periods[index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================
  Widget _buildProgressOverview() {
    // FIXED: Added missing minus sign
    final weightDiff = currentWeight - startingWeight;
    final diffLabel = weightDiff >= 0
        ? "+${weightDiff.toStringAsFixed(1)} kg"
        : "${weightDiff.toStringAsFixed(1)} kg";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biometric Snapshot',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const Text(
          'Live calculation of your active health streak',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Weight',
                value: '${currentWeight.toStringAsFixed(1)} kg',
                subtitle: diffLabel,
                gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.local_fire_department_outlined,
                title: 'Calories',
                value: '$caloriesAverage',
                subtitle: 'kcal avg.',
                gradient: const [Color(0xFFFF7E8B), Color(0xFFE91E8C)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.water_drop_outlined,
                title: 'Water',
                value: '${waterAverage.toStringAsFixed(1)}L',
                subtitle: 'daily avg.',
                gradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.15)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: gradient[1]),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: gradient[1],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEIGHT PROGRESS
  // ============================================================
  Widget _buildWeightProgress() {
    // FIXED: Added missing minus signs
    final totalDistance = (startingWeight - goalWeight).abs();
    final completed = (startingWeight - currentWeight).abs();
    final progress = totalDistance > 0 ? (completed / totalDistance).clamp(0.0, 1.0) : 0.0;
    final remainingWeight = (currentWeight - goalWeight).abs();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weight Trajectory',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${(progress * 100).round()}% complete',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeightPoint('Starting', '${startingWeight.toStringAsFixed(1)} kg', false),
              _buildWeightPoint('Current', '${currentWeight.toStringAsFixed(1)} kg', true),
              _buildWeightPoint('Goal Target', '${goalWeight.toStringAsFixed(1)} kg', false),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, val, child) {
                  return FractionallySizedBox(
                    widthFactor: val.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${remainingWeight.toStringAsFixed(1)} kg remaining to reach your target goal',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPoint(String label, String value, bool active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFFE91E8C) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NUTRITION ANALYTICS
  // ============================================================
  Widget _buildNutritionAnalytics() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Macro & Intake Quotas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Text(
                'Daily Average',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutritionRow(
            icon: Icons.local_fire_department_outlined,
            title: 'Calories',
            current: '$caloriesAverage kcal',
            target: '$caloriesTarget kcal',
            percentage: caloriesTarget > 0 ? caloriesAverage / caloriesTarget : 0.0,
            color: const Color(0xFFE91E8C),
          ),
          const SizedBox(height: 16),
          _buildNutritionRow(
            icon: Icons.fitness_center_outlined,
            title: 'Protein',
            current: '${proteinAverage}g',
            target: '${proteinTarget}g',
            percentage: proteinTarget > 0 ? proteinAverage / proteinTarget : 0.0,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 16),
          _buildNutritionRow(
            icon: Icons.water_drop_outlined,
            title: 'Water Goal',
            current: '${waterAverage.toStringAsFixed(1)}L',
            target: '${waterTarget.toStringAsFixed(1)}L',
            percentage: waterTarget > 0 ? waterAverage / waterTarget : 0.0,
            color: const Color(0xFF00ACC1),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow({
    required IconData icon,
    required String title,
    required String current,
    required String target,
    required double percentage,
    required Color color,
  }) {
    final safePercentage = percentage.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              current,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ $target',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: safePercentage),
          duration: const Duration(milliseconds: 1000),
          builder: (context, val, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // WATER PROGRESS
  // ============================================================
  Widget _buildWaterProgress() {
    final waterProgress = waterTarget > 0 ? (waterAverage / waterTarget).clamp(0.0, 1.0) : 0.0;

    return _buildGlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: waterProgress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return CircularProgressIndicator(
                        value: val,
                        strokeWidth: 6.5,
                        backgroundColor: const Color(0xFF00ACC1).withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
                      );
                    },
                  ),
                ),
                const Icon(Icons.water_drop_rounded, color: Color(0xFF00ACC1), size: 26),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hydration Index',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'You are maintaining an optimal fluid equilibrium.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    height: 1.3,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${waterAverage.toStringAsFixed(1)} L / ${waterTarget.toStringAsFixed(1)} L Goal',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00ACC1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEEKLY ACTIVITY (DYNAMIC BAR CHART)
  // ============================================================
  Widget _buildWeeklyActivity() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Consistency Chart',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Daily percentage completion rate',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 125,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weeklyActivity.isEmpty
                  ? [
                const Center(
                  child: Text(
                    "Not enough activity logged",
                    style: TextStyle(fontFamily: "Poppins", fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                )
              ]
                  : weeklyActivity.map((dayData) {
                final label = dayData['day'] as String? ?? '';
                final value = ((dayData['value'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: value),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutBack,
                      builder: (context, val, child) {
                        // FIXED: Corrected formula to avoid expression error
                        final barHeight = (72.0 * val).clamp(4.0, 72.0);
                        return Container(
                          width: 22,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STREAK CARD
  // ============================================================
  Widget _buildStreakCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3EB), Color(0xFFFFE8D6)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF8A3D).withValues(alpha: 0.35)),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Day Streak',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily health commitments completed for $currentStreak consecutive days.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // ============================================================
  // INSIGHT CARD
  // ============================================================
  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00ACC1).withValues(alpha: 0.12),
            const Color(0xFF008B87).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF00ACC1).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF008B87)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FitZen Adaptive Insight',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF008B87),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your nutrition consistency is improving steady macro distribution. Keep logging meals and staying hydrated to lock in your metabolic baseline.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================
  Widget _buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
            child: const _NavItem(icon: Icons.home_rounded, label: 'Home', active: false),
          ),
          const _NavItem(icon: Icons.trending_up_rounded, label: 'Progress', active: true),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: const _NavItem(icon: Icons.person_rounded, label: 'Profile', active: false),
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
    const inactiveColor = Color(0xFF94A3B8);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (active)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A3D).withValues(alpha: 0.14),
                  const Color(0xFFE91E8C).withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: activeColor, size: 19),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: activeColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else ...[
          Icon(icon, color: inactiveColor, size: 21),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: inactiveColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}