import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> with SingleTickerProviderStateMixin {
  // ============================================================
  // SCANNER STATE
  // ============================================================
  bool _isScanning = false;
  bool _isSaving = false;
  bool _isSavedSuccess = false;
  bool _fingerDetected = false;

  final List<SensorValue> _rawPPG = [];
  final List<int> _validBpmSamples = [];
  final List<double> _ibiListMs = [];

  int _liveBPM = 0;
  int _finalBPM = 0;
  int _energyScore = 0;
  int _stressScore = 0;
  int _hrvMs = 0;

  double _scanProgress = 0.0;
  static const int _requiredValidSamples = 12;

  late AnimationController _pulseController;
  late Animation<double> _pulseCurve;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    // Premium easing curve for a more natural heartbeat snap
    _pulseCurve = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // SCANNING LOGIC
  // ============================================================
  Future<void> _startScan() async {
    final camPerm = await Permission.camera.request();
    if (!camPerm.isGranted) {
      if (mounted) _showMessage('Camera permission is required to scan pulse', isError: true);
      return;
    }

    setState(() {
      _isScanning = true;
      _isSavedSuccess = false;
      _fingerDetected = false;
      _rawPPG.clear();
      _validBpmSamples.clear();
      _ibiListMs.clear();
      _liveBPM = 0;
      _scanProgress = 0.0;
    });

    _pulseController.repeat(reverse: true);
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
      _fingerDetected = false;
      _liveBPM = 0;
    });
    _pulseController.stop();
  }

  // STRICT FINGER DETECTION
  void _onRawData(SensorValue value) {
    if (!_isScanning) return;

    _rawPPG.add(value);
    if (_rawPPG.length > 30) {
      _rawPPG.removeAt(0);
    }

    if (_rawPPG.length >= 8) {
      final recent = _rawPPG.sublist(_rawPPG.length - 8).map((e) => e.value).toList();
      final mean = recent.reduce((a, b) => a + b) / recent.length;
      double variance = 0;
      for (final v in recent) {
        variance += (v - mean) * (v - mean);
      }
      variance /= recent.length;

      final bool hasFinger = mean > 40 && variance > 0.05 && variance < 4000;

      if (mounted && _fingerDetected != hasFinger) {
        setState(() {
          _fingerDetected = hasFinger;
          if (!hasFinger) {
            _liveBPM = 0;
            _pulseController.duration = const Duration(milliseconds: 750);
            if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
          }
        });
      }
    }
  }

  // CALCULATION
  void _onBPMUpdate(int rawBpm) {
    if (!_isScanning || !_fingerDetected) return;
    if (rawBpm < 45 || rawBpm > 185) return;

    int processedBpm = rawBpm;
    if (_validBpmSamples.isNotEmpty) {
      final last = _validBpmSamples.last;
      final diff = (rawBpm - last).abs();
      if (diff > 35) return;
      processedBpm = ((rawBpm * 0.6) + (last * 0.4)).round();
    }

    _validBpmSamples.add(processedBpm);
    _ibiListMs.add(60000.0 / processedBpm);

    final sorted = List<int>.from(_validBpmSamples)..sort();
    int stabilizedBpm;
    if (sorted.length >= 4) {
      final trimmed = sorted.sublist(1, sorted.length - 1);
      stabilizedBpm = (trimmed.reduce((a, b) => a + b) / trimmed.length).round();
    } else {
      stabilizedBpm = sorted[sorted.length ~/ 2];
    }

    final progress = (_validBpmSamples.length / _requiredValidSamples).clamp(0.0, 1.0);

    setState(() {
      _liveBPM = stabilizedBpm;
      _scanProgress = progress;

      int durationMs = (60000 / stabilizedBpm).round().clamp(300, 1200);
      _pulseController.duration = Duration(milliseconds: durationMs);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    });

    if (_validBpmSamples.length >= _requiredValidSamples) {
      _finishAndComputeMetrics(stabilizedBpm);
    }
  }

  void _finishAndComputeMetrics(int stabilizedBpm) {
    double sumSquaredDiffs = 0;
    int diffCount = 0;
    for (int i = 1; i < _ibiListMs.length; i++) {
      final diff = _ibiListMs[i] - _ibiListMs[i - 1];
      sumSquaredDiffs += diff * diff;
      diffCount++;
    }

    int computedHrv;
    if (diffCount > 0) {
      final rmssd = math.sqrt(sumSquaredDiffs / diffCount);
      computedHrv = rmssd.round().clamp(25, 110);
    } else {
      computedHrv = (90 - (stabilizedBpm - 60) * 0.7).round().clamp(30, 95);
    }

    final double hrFactor = ((stabilizedBpm - 60) / 60).clamp(0.0, 1.0);
    final double hrvFactor = (1.0 - ((computedHrv - 25) / 75)).clamp(0.0, 1.0);

    final int computedStress = ((hrFactor * 65) + (hrvFactor * 35)).round().clamp(15, 90);
    final int computedEnergy = (100 - (computedStress * 0.7)).round().clamp(20, 95);

    setState(() {
      _isScanning = false;
      _fingerDetected = false;
      _finalBPM = stabilizedBpm;
      _hrvMs = computedHrv;
      _stressScore = computedStress;
      _energyScore = computedEnergy;
    });

    _pulseController.stop();
  }

  // ============================================================
  // SAVE BIOMETRICS
  // ============================================================
  Future<void> _saveToGoogleSheet() async {
    if (_isSaving || _isSavedSuccess) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      await prefs.setInt('last_bpm', _finalBPM);
      await prefs.setInt('last_energy', _energyScore);
      await prefs.setInt('last_stress', _stressScore);
      await prefs.setInt('last_hrv', _hrvMs);

      if (email.isNotEmpty) {
        await ApiService.logHeartRate(
          email: email,
          heartRate: _finalBPM,
          energy: _energyScore,
          stress: _stressScore,
          hrv: _hrvMs,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSavedSuccess = true;
        });

        _showMessage('Biometrics saved successfully!', isError: false);
        await Future.delayed(const Duration(milliseconds: 900));

        if (mounted) {
          Navigator.pop(context, {
            'bpm': _finalBPM,
            'energy': _energyScore,
            'stress': _stressScore,
            'hrv': _hrvMs,
          });
        }
      }
    } catch (e) {
      debugPrint('Save Biometrics Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage('Failed to save biometrics', isError: true);
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                          "Heart Rate Scan",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Measure your pulse, HRV, and stress levels.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),

                        // MAIN SCANNING / RESULT UI
                        _buildScannerCard(),
                        const SizedBox(height: 24),

                        // START / CANCEL BUTTON
                        _buildScanButton(),
                        const SizedBox(height: 24),

                        // INSTRUCTIONS SECTION
                        if (!_isScanning && _finalBPM == 0) ...[
                          _buildInstructionsCard(),
                        ],

                        // BIOMETRIC RESULTS CARDS
                        if (_finalBPM > 0 && !_isScanning) ...[
                          Row(
                            children: [
                              Expanded(child: _biometricCard(title: 'Energy', value: '$_energyScore%', subtitle: _energyScore >= 70 ? 'High' : 'Moderate', icon: Icons.bolt_rounded, color: const Color(0xFFFF8A3D))),
                              const SizedBox(width: 8),
                              Expanded(child: _biometricCard(title: 'Stress', value: '$_stressScore%', subtitle: _stressScore <= 40 ? 'Relaxed' : 'Elevated', icon: Icons.psychology_outlined, color: const Color(0xFFE91E8C))),
                              const SizedBox(width: 8),
                              Expanded(child: _biometricCard(title: 'HRV', value: '$_hrvMs ms', subtitle: _hrvMs >= 50 ? 'Optimal' : 'Low', icon: Icons.timeline_rounded, color: const Color(0xFF26C6DA))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // SAVE BIOMETRICS BUTTON
                          _buildSaveButton(),
                        ],
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
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Vitals Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E8C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text("PPG SENSOR", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFE91E8C), fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return _buildGlassCard(
      shadowColor: const Color(0xFFE91E8C).withOpacity(0.15),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildGlowingHeartView(),
                  const SizedBox(width: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (_fingerDetected && _liveBPM > 0) ? '$_liveBPM' : '--',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1, fontFamily: 'Poppins', letterSpacing: -1.5),
                      ),
                      const SizedBox(width: 6),
                      const Text('bpm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _fingerDetected ? _scanProgress : 0.0,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E8C)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _fingerDetected ? 'Signal Locked • ${(_scanProgress * 100).toInt()}%' : '⚠️ Place finger firmly over camera & flash!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _fingerDetected ? const Color(0xFF059669) : const Color(0xFFFF8A3D), fontFamily: 'Poppins'),
            ),
          ] else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, size: 65, color: Color(0xFFE91E8C)),
                  const SizedBox(width: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _finalBPM > 0 ? '$_finalBPM' : '--',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1, fontFamily: 'Poppins', letterSpacing: -1.5),
                      ),
                      const SizedBox(width: 6),
                      const Text('bpm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _finalBPM > 0 ? 'Scan Complete' : 'Ready to Scan',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontFamily: 'Poppins'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: _isScanning
              ? null
              : const LinearGradient(colors: [Color(0xFFFF5287), Color(0xFFE91E8C)]), // Premium solid pink
          color: _isScanning ? Colors.white.withOpacity(0.8) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isScanning
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: _isScanning ? _stopScan : _startScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: _isScanning ? const Color(0xFF1E293B) : Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _isScanning ? const BorderSide(color: Colors.white, width: 1.5) : BorderSide.none
            ),
          ),
          child: Text(
            _isScanning ? 'Cancel Scan' : (_finalBPM > 0 ? 'Scan Again' : 'Start Pulse Scan'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFF1E293B), size: 20),
              SizedBox(width: 8),
              Text('How to measure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(height: 16),
          _instructionStep('1', 'Cover BOTH the rear camera lens and flashlight firmly with your fingertip.'),
          _instructionStep('2', 'Keep your hand completely still and apply light, even pressure.'),
          _instructionStep('3', 'Hold steady for 5–7 seconds until the progress bar completes.'),
        ],
      ),
    );
  }

  Widget _instructionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(step, style: const TextStyle(color: Color(0xFFE91E8C), fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.4, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _biometricCard({required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), // Tighter horizontal padding to avoid overflow
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins', letterSpacing: -0.5))),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontFamily: 'Poppins'))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedScale(
      scale: _isSaving ? 0.96 : (_isSavedSuccess ? 1.03 : 1.0),
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            gradient: _isSavedSuccess ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]) : const LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: (_isSavedSuccess ? const Color(0xFF10B981) : const Color(0xFF008B87)).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveToGoogleSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_isSavedSuccess ? Icons.check_circle_rounded : Icons.cloud_upload_outlined, size: 20),
            label: Text(
              _isSaving ? 'Saving to Sheet...' : (_isSavedSuccess ? 'Saved Successfully!' : 'Save Biometrics'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingHeartView() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fingerDetected ? (1.0 + (_pulseCurve.value * 0.12)) : 1.0, // Smoother pulse
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner core glow
          ClipPath(
            clipper: HeartClipper(),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const RadialGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)], center: Alignment.center, radius: 0.8),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.6), blurRadius: 20, spreadRadius: 4),
                  BoxShadow(color: const Color(0xFFFF8A3D).withOpacity(0.3), blurRadius: 35, spreadRadius: 10),
                ],
              ),
            ),
          ),
          // Actual camera overlay
          ClipPath(
            clipper: HeartClipper(),
            child: Container(
              width: 72,
              height: 72,
              foregroundDecoration: BoxDecoration(color: const Color(0xFFE91E8C).withOpacity(0.2), backgroundBlendMode: BlendMode.overlay),
              child: HeartBPMDialog(
                context: context,
                showTextValues: false,
                borderRadius: 0,
                cameraWidgetWidth: 72,
                cameraWidgetHeight: 72,
                sampleDelay: 1000 ~/ 30,
                onRawData: _onRawData,
                onBPM: _onBPMUpdate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double width = size.width;
    double height = size.height;

    path.moveTo(width / 2, height * 0.25);
    path.cubicTo(width * 0.8, -height * 0.15, width * 1.3, height * 0.4, width / 2, height * 0.95);
    path.moveTo(width / 2, height * 0.25);
    path.cubicTo(width * 0.2, -height * 0.15, -width * 0.3, height * 0.4, width / 2, height * 0.95);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}