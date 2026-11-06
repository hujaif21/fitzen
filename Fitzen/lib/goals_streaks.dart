import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'home.dart';
import 'progress.dart';
import 'profile.dart';
import 'core_settings.dart'; // 🚨 Integrated for dynamic themes & AppColors
import 'network/api_service.dart';

class GoalsStreaksPage extends StatefulWidget {
  const GoalsStreaksPage({super.key});

  @override
  State<GoalsStreaksPage> createState() => _GoalsStreaksPageState();
}

class _GoalsStreaksPageState extends State<GoalsStreaksPage> {
  // ============================================================
  // DYNAMIC DATA
  // ============================================================

  bool isLoading = true;
  String userEmail = '';

  int currentStreak = 0;
  int bestStreak = 0;

  double calConsumed = 0;
  double calTarget = 2200;

  double waterConsumedML = 0;
  double waterTargetML = 2500;

  double currentWeight = 0;
  double weightGoal = 55.0;

  Map<String, dynamic> consistencyMap = {};

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      if (userEmail.isNotEmpty) {
        final response = await ApiService.getStreaksData(userEmail);

        if (response['status'] == 'success') {
          setState(() {
            currentStreak = response['currentStreak'] ?? 0;
            bestStreak = response['bestStreak'] ?? 0;

            final cals = response['calories'] ?? {};
            calConsumed = (cals['consumed'] as num?)?.toDouble() ?? 0;
            calTarget = (cals['target'] as num?)?.toDouble() ?? 2200;

            final water = response['water'] ?? {};
            waterConsumedML = (water['consumed'] as num?)?.toDouble() ?? 0;
            waterTargetML = (water['target'] as num?)?.toDouble() ?? 2500;

            final weight = response['weight'] ?? {};
            currentWeight = (weight['current'] as num?)?.toDouble() ?? 0;
            weightGoal = (weight['target'] as num?)?.toDouble() ?? 55.0;

            consistencyMap = response['consistency'] ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading streaks: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        final isDark = AppColors.isDark(context);

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Stack(
            children: [
              _buildAuroraBackground(context),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
                      )
                          : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopStatus(context),
                            const SizedBox(height: 16),
                            _buildStreakCard(context),
                            const SizedBox(height: 24),

                            // ==========================================
                            // YOUR GOALS SECTION
                            // ==========================================
                            Row(
                              children: [
                                Text(
                                  'Your Goals',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Spacer(),
                                _addGoalButton(context),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _goalCard(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              iconGradient: const [Color(0xFFFF7E8B), Color(0xFFE91E8C)],
                              title: 'Daily Calorie Target',
                              subtitle: 'Target: ${calTarget.toInt()} kcal',
                              progressText: '${calConsumed.toInt()} / ${calTarget.toInt()} kcal',
                              percentage: '${(calTarget > 0 ? (calConsumed / calTarget) * 100 : 0).clamp(0, 100).toInt()}%',
                              progress: calTarget > 0 ? calConsumed / calTarget : 0.0,
                              progressGradient: const [Color(0xFFFF7E8B), Color(0xFFE91E8C)],
                            ),
                            const SizedBox(height: 12),

                            _goalCard(
                              context,
                              icon: Icons.water_drop_rounded,
                              iconGradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
                              title: 'Daily Water Target',
                              subtitle: 'Target: ${(waterTargetML / 1000).toStringAsFixed(1)} L',
                              progressText: '${(waterConsumedML / 1000).toStringAsFixed(1)} / ${(waterTargetML / 1000).toStringAsFixed(1)} L',
                              percentage: '${(waterTargetML > 0 ? (waterConsumedML / waterTargetML) * 100 : 0).clamp(0, 100).toInt()}%',
                              progress: waterTargetML > 0 ? waterConsumedML / waterTargetML : 0.0,
                              progressGradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
                            ),
                            const SizedBox(height: 12),

                            // FIXED: Corrected weight difference math syntax error
                            Builder(
                              builder: (context) {
                                final double weightDiff = (currentWeight - weightGoal).abs();
                                final double progressVal = currentWeight > 0 ? (currentWeight <= weightGoal ? 1.0 : 0.6) : 0.0;
                                return _goalCard(
                                  context,
                                  icon: Icons.monitor_weight_rounded,
                                  iconGradient: const [Color(0xFF34D399), Color(0xFF059669)],
                                  title: 'Weight Goal',
                                  subtitle: 'Target: ${weightGoal.toStringAsFixed(1)} kg',
                                  progressText: currentWeight > 0 ? 'Current: ${currentWeight.toStringAsFixed(1)} kg' : 'No recent log',
                                  percentage: currentWeight > 0 ? '${weightDiff.toStringAsFixed(1)} kg away' : '-',
                                  progress: progressVal,
                                  progressGradient: const [Color(0xFF34D399), Color(0xFF059669)],
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                            _buildWellnessGoal(context),
                            const SizedBox(height: 20),
                            _buildConsistency(context),
                            const SizedBox(height: 24),

                            // ==========================================
                            // STREAK MILESTONES
                            // ==========================================
                            Row(
                              children: [
                                Text(
                                  'Streak Milestones',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_calculateUnlockedBadges()} / 4 Unlocked',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF00ACC1),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _milestoneCard(
                              context,
                              icon: '🥉',
                              title: '3-Day Starter',
                              subtitle: bestStreak >= 3 ? 'Bronze badge earned' : 'Complete 3 days',
                              status: bestStreak >= 3 ? 'Unlocked ✓' : 'Locked',
                              unlocked: bestStreak >= 3,
                            ),
                            const SizedBox(height: 10),

                            _milestoneCard(
                              context,
                              icon: '🥈',
                              title: '7-Day Consistent',
                              subtitle: bestStreak >= 7 ? 'Silver badge active' : 'Complete 7 days',
                              status: currentStreak == 7 ? '🔥 Unlocked Today' : (bestStreak >= 7 ? 'Unlocked ✓' : 'Locked'),
                              unlocked: bestStreak >= 7,
                              today: currentStreak == 7,
                            ),
                            const SizedBox(height: 10),

                            _milestoneCard(
                              context,
                              icon: '🥇',
                              title: '14-Day Master',
                              subtitle: bestStreak >= 14 ? 'Gold badge earned' : '${math.min(currentStreak, 14)} / 14 days completed',
                              status: bestStreak >= 14 ? 'Unlocked ✓' : '${((currentStreak / 14) * 100).toInt()}%',
                              unlocked: bestStreak >= 14,
                              showProgress: bestStreak < 14,
                              progressVal: (currentStreak / 14).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 10),

                            _milestoneCard(
                              context,
                              icon: '🔒',
                              title: '30-Day Zen Master',
                              subtitle: bestStreak >= 30 ? 'Zen Master status achieved' : '${math.min(currentStreak, 30)} / 30 days completed',
                              status: bestStreak >= 30 ? 'Unlocked ✓' : 'Locked',
                              unlocked: bestStreak >= 30,
                              showProgress: bestStreak < 30 && bestStreak > 0,
                              progressVal: (currentStreak / 30).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomNavigation(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateUnlockedBadges() {
    int count = 0;
    if (bestStreak >= 3) count++;
    if (bestStreak >= 7) count++;
    if (bestStreak >= 14) count++;
    if (bestStreak >= 30) count++;
    return count;
  }

  // ============================================================
  // UI GLASS & AURORA HELPERS
  // ============================================================

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

  Widget _buildGlassCard(BuildContext context, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20), Color? shadowColor}) {
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.card(context).withOpacity(0.85),
        border: Border(bottom: BorderSide(color: AppColors.border(context), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 19, color: AppColors.textPrimary(context)),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('F', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
              child: Text(
                'FitZen Goals & Streaks',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP STATUS
  // ============================================================

  Widget _buildTopStatus(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Stay consistent, one milestone at a time.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.3, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF26C6DA).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF26C6DA).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF00ACC1)),
              SizedBox(width: 4),
              Text('Active Pace', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF00ACC1), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STREAK CARD
  // ============================================================

  Widget _buildStreakCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E8C).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$currentStreak Day Streak',
                        style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                        child: const Text('LIVE', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Mindful wellness momentum', style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withOpacity(0.9), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep logging daily to extend your streak and unlock executive milestones!',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withOpacity(0.95), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _streakStat('Current Streak', '$currentStreak Days')),
              const SizedBox(width: 10),
              Expanded(child: _streakStat('Best Streak', '$bestStreak Days')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakStat(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ============================================================
  // ADD GOAL BUTTON
  // ============================================================

  Widget _addGoalButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF008B87)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const Row(
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text('Add Goal', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ============================================================
  // GOAL CARD (WITH ANIMATION)
  // ============================================================

  Widget _goalCard(
      BuildContext context, {
        required IconData icon,
        required List<Color> iconGradient,
        required String title,
        required String subtitle,
        required String progressText,
        required String percentage,
        required double progress,
        required List<Color> progressGradient,
      }) {
    final double safeProgress = progress.clamp(0.0, 1.0);

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconGradient[0].withOpacity(0.18), iconGradient[1].withOpacity(0.18)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconGradient[1].withOpacity(0.3)),
                ),
                child: Icon(icon, color: iconGradient[1], size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary(context)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(progressText, style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(percentage, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: progressGradient[1], fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),

          // ANIMATED PROGRESS BAR
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: safeProgress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation<Color>(progressGradient[1]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WELLNESS GOAL
  // ============================================================

  Widget _buildWellnessGoal(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Color(0xFFE91E8C), size: 19),
              const SizedBox(width: 8),
              Text('Set Wellness Goal', style: TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border(context))),
                child: Text('Close', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Goal Type', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _inputBox(
            context,
            child: Row(
              children: [
                Text('Weight', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary(context)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Goal Value', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _inputBox(
            context,
            child: Row(
              children: [
                Text(weightGoal.toStringAsFixed(1), style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(10)),
                  child: Text('kg', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Save Goal', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox(BuildContext context, {required Widget child}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 1.2),
      ),
      child: Center(child: child),
    );
  }

  // ============================================================
  // CONSISTENCY CALENDAR (DYNAMIC)
  // ============================================================

  Widget _buildConsistency(BuildContext context) {
    final now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<String> monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    int trackedCount = 0;
    List<List<dynamic>> dynamicDays = [];
    for (int i = 1; i <= daysInMonth; i++) {
      String d = i.toString().padLeft(2, '0');
      String m = now.month.toString().padLeft(2, '0');
      String dateStr = "$d/$m/${now.year}";

      bool isTracked = consistencyMap[dateStr] == true;
      if (isTracked) trackedCount++;

      dynamicDays.add([i.toString(), isTracked]);
    }

    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${monthNames[now.month]} Consistency', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                  const SizedBox(height: 2),
                  Text('$trackedCount of ${now.day} days tracked', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary(context))),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textSecondary(context)),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary(context)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) => Text(day, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context)))).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              dynamicDays.length,
                  (index) {
                final day = dynamicDays[index][0] as String;
                final completed = dynamicDays[index][1] as bool;
                final isToday = day == now.day.toString();
                final isFuture = int.parse(day) > now.day;

                return Container(
                  width: 33,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFE91E8C)
                        : completed
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : isFuture
                        ? Colors.transparent
                        : AppColors.border(context),
                    borderRadius: BorderRadius.circular(10),
                    border: isFuture ? Border.all(color: AppColors.border(context)) : null,
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: isToday
                            ? Colors.white
                            : completed
                            ? const Color(0xFF10B981)
                            : isFuture
                            ? AppColors.textSecondary(context).withOpacity(0.4)
                            : AppColors.textSecondary(context),
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _LegendDot(color: Color(0xFF10B981), label: 'Goal Completed'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF94A3B8), label: 'Missed/Future'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFFE91E8C), label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MILESTONE CARD
  // ============================================================

  Widget _milestoneCard(
      BuildContext context, {
        required String icon,
        required String title,
        required String subtitle,
        required String status,
        required bool unlocked,
        bool today = false,
        bool showProgress = false,
        double progressVal = 0.0,
      }) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.all(14),
      shadowColor: unlocked && today ? const Color(0xFFE91E8C).withOpacity(0.12) : null,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFFFFB259).withOpacity(0.2) : AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: unlocked ? const Color(0xFFFFB259).withOpacity(0.4) : AppColors.border(context)),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: AppColors.textSecondary(context))),
                if (showProgress) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressVal,
                      minHeight: 6,
                      backgroundColor: AppColors.border(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked
                  ? (today ? const Color(0xFFE91E8C).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.15))
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unlocked ? (today ? const Color(0xFFE91E8C) : const Color(0xFF10B981)) : AppColors.border(context),
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                color: unlocked ? (today ? const Color(0xFFE91E8C) : const Color(0xFF10B981)) : AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.cardGlass(context),
            border: Border(top: BorderSide(color: AppColors.border(context), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                child: const _NavItem(icon: Icons.home_rounded, label: 'Home', active: false),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProgressPage())),
                child: const _NavItem(icon: Icons.trending_up_rounded, label: 'Progress', active: false),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: const _NavItem(icon: Icons.person_rounded, label: 'Profile', active: false),
              ),
            ],
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A3D).withOpacity(0.14),
                  const Color(0xFFE91E8C).withOpacity(0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: activeColor, size: 21),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else ...[
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

// ============================================================
// LEGEND DOT
// ============================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)),
      ],
    );
  }
}