import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class PedometerScreen extends StatefulWidget {
  const PedometerScreen({super.key});

  @override
  State<PedometerScreen> createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  // ============================================================
  // PEDOMETER STATE
  // ============================================================
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  int _todaySteps = 0;
  int _sessionSteps = 0;
  int? _sensorBaseline;
  int _stepsBeforeSession = 0;

  bool _isTracking = false;
  bool _isSaving = false;
  String _pedestrianStatus = 'Stopped';
  String _sensorMessage = 'Tap "Start Walking" and carry your phone securely';

  // User Profile Metrics Loaded from Registration
  double _userWeightKg = 60.0;
  String _userGoal = 'Gain Weight';

  @override
  void initState() {
    super.initState();
    _loadSavedStepsAndProfile();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.day}_${now.month}_${now.year}';
  }

  // ============================================================
  // LOAD & SYNC DATA
  // ============================================================
  Future<void> _loadSavedStepsAndProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedWeight = prefs.getDouble('userWeight') ?? prefs.getDouble('currentWeight');
    final savedGoal = prefs.getString('userGoal') ?? prefs.getString('goal');

    setState(() {
      if (savedWeight != null && savedWeight > 0) _userWeightKg = savedWeight;
      if (savedGoal != null && savedGoal.isNotEmpty) _userGoal = savedGoal;
    });

    final key = 'steps_${_todayKey()}';
    final localSteps = prefs.getInt(key) ?? 0;

    setState(() {
      _todaySteps = localSteps;
      _stepsBeforeSession = localSteps;
    });

    final email = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';
    if (email.isNotEmpty) {
      try {
        final res = await ApiService.getSteps(email);
        if (res['status'] == 'success') {
          final cloudSteps = (res['steps'] as num?)?.toInt() ?? 0;
          if (cloudSteps > _todaySteps && mounted) {
            setState(() {
              _todaySteps = cloudSteps;
              _stepsBeforeSession = cloudSteps;
            });
            await prefs.setInt(key, cloudSteps);
          }
        }
      } catch (_) {}
    }
  }

  // ============================================================
  // TRACKING LOGIC & MATH (Operators Fixed)
  // ============================================================
  Future<void> _startTracking() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _showMessage('Physical Activity permission denied in settings.', isError: true);
      return;
    }

    setState(() {
      _isTracking = true;
      _sensorBaseline = null;
      _sessionSteps = 0;
      _stepsBeforeSession = _todaySteps;
      _sensorMessage = 'Sensor active. Walk naturally!';
    });

    _stepSubscription?.cancel();
    _statusSubscription?.cancel();

    _stepSubscription = Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepError, cancelOnError: false);
    _statusSubscription = Pedometer.pedestrianStatusStream.listen(_onPedestrianStatusChanged, onError: (_) {});
  }

  void _stopTracking() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    setState(() {
      _isTracking = false;
      _pedestrianStatus = 'Paused';
      _sensorMessage = 'Tracking paused. Tap Save to sync.';
    });
  }

  Future<void> _resetTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_${_todayKey()}', 0);
    setState(() {
      _sensorBaseline = null;
      _sessionSteps = 0;
      _todaySteps = 0;
      _stepsBeforeSession = 0;
      _sensorMessage = 'Counter reset to 0.';
    });
  }

  void _onStepCount(StepCount event) async {
    if (_sensorBaseline == null) _sensorBaseline = event.steps;
    if (event.steps < _sensorBaseline!) _sensorBaseline = event.steps;

    final int delta = event.steps - _sensorBaseline!; // Fixed Math
    final int updatedToday = _stepsBeforeSession + delta;

    if (mounted) {
      setState(() {
        _sessionSteps = delta;
        _todaySteps = updatedToday;
        _sensorMessage = 'Real-time step counting active';
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_${_todayKey()}', _todaySteps);
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _pedestrianStatus = event.status.toLowerCase() == 'walking' ? 'Walking' : 'Stopped';
    });
  }

  void _onStepError(dynamic error) {
    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _sensorMessage = 'Hardware step detector unavailable';
    });
  }

  // ============================================================
  // CALCULATIONS (Operators Fixed)
  // ============================================================
  int get _dailyStepGoal {
    String goalLower = _userGoal.toLowerCase();
    if (goalLower.contains('lose') || goalLower.contains('cut')) {
      return (_userWeightKg * 135).clamp(6000, 12000).toInt(); // Fixed Math
    } else if (goalLower.contains('muscle') || goalLower.contains('gain')) {
      return (_userWeightKg * 105).clamp(5000, 9000).toInt(); // Fixed Math
    }
    return (_userWeightKg * 115).clamp(6000, 10000).toInt(); // Fixed Math
  }

  double get _caloriesBurned {
    double calories = _todaySteps * 0.0005 * _userWeightKg; // Fixed Math
    return double.parse(calories.toStringAsFixed(1));
  }

  double get _distanceKM => double.parse((_todaySteps * 0.000762).toStringAsFixed(2)); // Fixed Math

  String get _goalContextMessage {
    String goalLower = _userGoal.toLowerCase();
    int target = _dailyStepGoal;
    if (goalLower.contains('lose') || goalLower.contains('cut')) {
      return '🔥 Weight Loss Plan: Walk $target steps today to maximize fat burn!';
    } else if (goalLower.contains('muscle') || goalLower.contains('gain')) {
      return '💪 Muscle Gain Plan: Aim for $target steps for active recovery.';
    }
    return '🎯 Tailored daily target of $target steps for your baseline.';
  }

  // ============================================================
  // SAVE TO CLOUD
  // ============================================================
  Future<void> _saveStepsToSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

    if (email.isEmpty) {
      _showMessage('User email not found. Please log in.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.logSteps(
        email: email,
        steps: _todaySteps,
        caloriesBurned: _caloriesBurned,
        distanceKM: _distanceKM,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        _showMessage('Steps synced successfully!', isError: false);
      } else {
        _showMessage(response['message'] ?? 'Saved offline. Will sync later.', isError: true);
      }
    } catch (e) {
      if (mounted) _showMessage('Saved locally (Offline Mode)', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? const Color(0xFFE91E8C) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final int dynamicGoal = _dailyStepGoal;
    final double progress = (_todaySteps / dynamicGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Theme background
      body: Stack(
        children: [
          // 1. Premium Aurora Mesh Background
          _buildAuroraBackground(),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTrackerTag(),
                        const SizedBox(height: 12),
                        const Text(
                          "Activity & Steps",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Monitor your daily movement and vitality.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),

                        _buildProfileContextCard(),
                        const SizedBox(height: 24),

                        _buildMainPedometerCard(progress, dynamicGoal),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: _buildMetricCard(icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF8A3D), label: 'Calories Burned', value: '$_caloriesBurned', unit: 'kcal')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildMetricCard(icon: Icons.map_rounded, color: const Color(0xFF26C6DA), label: 'Distance Covered', value: '$_distanceKM', unit: 'km')),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        _buildPrimaryButton(
                          label: _isTracking ? 'Pause Walking' : 'Start Walking',
                          icon: _isTracking ? Icons.pause_rounded : Icons.directions_walk_rounded,
                          isTracking: _isTracking,
                          onTap: _isTracking ? _stopTracking : _startTracking,
                        ),
                        const SizedBox(height: 16),
                        _buildSecondaryButton(
                          label: _isSaving ? 'Syncing...' : 'Save Steps to Diary',
                          icon: Icons.cloud_upload_outlined,
                          isLoading: _isSaving,
                          onTap: _isSaving ? () {} : _saveStepsToSheet,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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
  // UI COMPONENTS
  // ============================================================
  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Positioned(top: -50, right: -50, child: Container(width: 350, height: 350, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x30FF8A3D)))),
        Positioned(bottom: 100, left: -100, child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x3000ACC1)))),
        Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(24), Color? shadowColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: shadowColor ?? Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A3D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF8A3D).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF8A3D), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text("REAL-TIME SENSOR", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFFF8A3D), fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _resetTodaySteps,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContextCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_rounded, color: Color(0xFFE91E8C), size: 18),
              const SizedBox(width: 8),
              Text('Weight: ${_userWeightKg.toInt()} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFF8A3D).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('Goal: $_userGoal', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFFF8A3D), fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPedometerCard(double progress, int dynamicGoal) {
    return _buildGlassCard(
      shadowColor: const Color(0xFFFF8A3D).withOpacity(0.1),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isTracking ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isTracking ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _pedestrianStatus == 'Walking' ? Icons.directions_walk_rounded : Icons.accessibility_new_rounded,
                  size: 16,
                  color: _isTracking ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  _isTracking ? 'Status: $_pedestrianStatus' : 'Idle',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _isTracking ? const Color(0xFF059669) : const Color(0xFF64748B), fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: StepCirclePainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk_rounded, size: 28, color: Color(0xFFFF8A3D)),
                    const SizedBox(height: 4),
                    Text(
                      '$_todaySteps',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
                    ),
                    Text(
                      'Target: $dynamicGoal',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Current Walk Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE91E8C), fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text('$_sessionSteps steps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white)),
            child: Text(
              _sensorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B), fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color color, required String label, required String value, required String unit}) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins', letterSpacing: -0.5)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, required bool isTracking, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isTracking ? [const Color(0xFF334155), const Color(0xFF1E293B)] : [const Color(0xFFFF8A3D), const Color(0xFFE91E8C)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: (isTracking ? const Color(0xFF1E293B) : const Color(0xFFE91E8C)).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20, color: Colors.white),
          label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required IconData icon, required bool isLoading, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon, size: 20, color: const Color(0xFF1E293B)),
        label: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E293B)))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          // FIX: Changed 'border: Border.all(...)' to 'side: const BorderSide(...)'
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white, width: 1.5)
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM PROGRESS CIRCLE PAINTER
// ============================================================
class StepCirclePainter extends CustomPainter {
  final double progress;

  StepCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;

    // Track
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient Sweep
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint); // Fixed Math
    }
  }

  @override
  bool shouldRepaint(covariant StepCirclePainter oldDelegate) => oldDelegate.progress != progress;
}