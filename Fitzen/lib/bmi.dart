import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:fitzen/home.dart';
import 'package:fitzen/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class BMIPage extends StatefulWidget {
  const BMIPage({super.key});

  @override
  State<BMIPage> createState() => _BMIPageState();
}

class _BMIPageState extends State<BMIPage> {
  // ============================================================
  // DYNAMIC DATA
  // ============================================================
  bool isLoading = true;
  String userEmail = '';

  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  double bmi = 0.0;
  String latestWeightDate = '';

  // Previous Record Data (Saved locally)
  double prevBmi = 0.0;
  String prevDate = '';
  String prevCategory = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      final savedHeight = prefs.getString('userHeight') ?? '';
      if (savedHeight.isNotEmpty) heightController.text = savedHeight;

      prevBmi = prefs.getDouble('prevBmi') ?? 0.0;
      prevDate = prefs.getString('prevBmiDate') ?? '';
      prevCategory = prefs.getString('prevBmiCategory') ?? '';

      if (userEmail.isNotEmpty) {
        final response = await ApiService.getWeightLogs(userEmail);

        if (response['status'] == 'success') {
          final logs = List<Map<String, dynamic>>.from(response['logs'] ?? []);

          if (logs.isNotEmpty) {
            final latestLog = logs.last;
            weightController.text = double.parse(latestLog['weight'].toString()).toStringAsFixed(1);
            latestWeightDate = latestLog['date'].toString();
          } else {
            final startingWeight = double.tryParse(response['startingWeight'].toString()) ?? 60.0;
            weightController.text = startingWeight.toStringAsFixed(1);
            latestWeightDate = "Profile";
          }
        }
      }

      if (heightController.text.isNotEmpty && weightController.text.isNotEmpty) {
        _calculateBMI(showError: false);
      }
    } catch (e) {
      debugPrint("Error loading BMI data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // CALCULATE BMI
  // ============================================================
  Future<void> _calculateBMI({bool showError = true}) async {
    final double? height = double.tryParse(heightController.text);
    final double? weight = double.tryParse(weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      if (showError && mounted) _showMessage('Please enter valid height and weight', isError: true);
      return;
    }

    final double heightInMeter = height / 100;
    setState(() {
      bmi = weight / (heightInMeter * heightInMeter);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userHeight', heightController.text);
  }

  // ============================================================
  // SAVE BMI RECORD
  // ============================================================
  Future<void> _saveBMIRecord() async {
    if (bmi <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '$day ${months[now.month]}';

    await prefs.setDouble('prevBmi', bmi);
    await prefs.setString('prevBmiDate', dateStr);
    await prefs.setString('prevBmiCategory', bmiCategory);

    setState(() {
      prevBmi = bmi;
      prevDate = dateStr;
      prevCategory = bmiCategory;
    });

    if (mounted) _showMessage('BMI result saved to history', isError: false);
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
  // CATEGORIES
  // ============================================================
  String get bmiCategory {
    if (bmi == 0) return '---';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiCategoryColor {
    if (bmi == 0) return const Color(0xFFCBD5E1);
    if (bmi < 18.5) return const Color(0xFF26C6DA); // Cyan
    if (bmi < 25) return const Color(0xFF10B981);   // Mint
    if (bmi < 30) return const Color(0xFFFF8A3D);   // Orange
    return const Color(0xFFE91E8C);                 // Pink
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
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTrackerTag(),
                        const SizedBox(height: 12),
                        const Text(
                          "Body Mass Index",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Understand your baseline vitality index.",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),

                        _buildMeasurementsCard(),
                        const SizedBox(height: 24),

                        _buildBMIResultCard(),
                        const SizedBox(height: 24),

                        _buildClinicalContext(),
                        const SizedBox(height: 32),

                        // Save Button (Updated to Pink/Orange Theme)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _saveBMIRecord,
                              icon: const Icon(Icons.bookmark_outline_rounded, size: 20, color: Colors.white),
                              label: const Text('Save BMI Result', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Reset Button (Fixed BorderSide bug)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() { heightController.clear(); bmi = 0.0; }),
                            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 20),
                            label: const Text('Reset Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.7),
                              foregroundColor: const Color(0xFF334155),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Colors.white, width: 1.5) // Fix applied here
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (prevBmi > 0) ...[
                          const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                          const SizedBox(height: 16),
                          _buildPreviousRecord(),
                          const SizedBox(height: 32),
                        ],

                        _buildHolisticTip(),
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
  // BACKGROUND & CORE UI COMPONENTS
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
        color: const Color(0xFFE91E8C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text("MINDFUL BIOMETRICS", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFE91E8C), fontFamily: 'Poppins')),
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
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('BMI Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARDS
  // ============================================================
  Widget _buildMeasurementsCard() {
    return _buildGlassCard(
      shadowColor: const Color(0xFFE91E8C).withOpacity(0.1),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Measurements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins'))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: const Text('Metric', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Height', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          _buildInputField(controller: heightController, icon: Icons.straighten_rounded, suffix: 'cm'),
          const SizedBox(height: 20),
          const Text('Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          _buildInputField(controller: weightController, icon: Icons.monitor_weight_rounded, suffix: 'kg'),
          const SizedBox(height: 10),
          if (latestWeightDate.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text('Prefilled from $latestWeightDate', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontFamily: 'Poppins')),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton.icon(
                onPressed: _calculateBMI,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                label: const Text('Calculate BMI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required IconData icon, required String suffix}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1.5)),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins'), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero))),
          Text(suffix, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildBMIResultCard() {
    double pointerFlex = 0;
    if (bmi > 0) {
      if (bmi < 15) pointerFlex = 0.05;
      else if (bmi > 35) pointerFlex = 0.95;
      else pointerFlex = (bmi - 15) / 20;
    }

    return _buildGlassCard(
      shadowColor: bmi > 0 ? bmiCategoryColor.withOpacity(0.15) : null,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Text('Your Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins'))),
              Text('Just now', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                bmi > 0 ? bmi.toStringAsFixed(1) : '0.0',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 16),
              if (bmi > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: bmiCategoryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: bmiCategoryColor.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: bmiCategoryColor),
                      const SizedBox(width: 6),
                      Text(bmiCategory, style: TextStyle(fontSize: 12, color: bmiCategoryColor, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Healthy range for your metabolic profile is 18.5 - 24.9.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B), fontFamily: 'Poppins')),
          const SizedBox(height: 32),

          if (bmi > 0) ...[
            FractionallySizedBox(
              widthFactor: 1.0,
              child: Align(
                alignment: Alignment((pointerFlex * 2) - 1, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: Text('${bmi.toStringAsFixed(1)} (You)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(flex: 18, child: Container(height: 10, color: const Color(0xFF26C6DA))), // Under
                Expanded(flex: 25, child: Container(height: 10, color: const Color(0xFF10B981))), // Normal
                Expanded(flex: 25, child: Container(height: 10, color: const Color(0xFFFF8A3D))), // Over
                Expanded(flex: 20, child: Container(height: 10, color: const Color(0xFFE91E8C))), // Obese
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRangeLabel('< 18.5', 'Under')),
              Expanded(child: _buildRangeLabel('18.5–24.9', 'Normal', color: const Color(0xFF059669))),
              Expanded(child: _buildRangeLabel('25.0–29.9', 'Over')),
              Expanded(child: _buildRangeLabel('≥ 30.0', 'Obese')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeLabel(String value, String label, {Color color = const Color(0xFF64748B)}) {
    return Column(
      children: [
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildClinicalContext() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF26C6DA).withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF26C6DA).withOpacity(0.3))), child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF008B87), size: 22)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinical Context', style: TextStyle(fontSize: 14.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                SizedBox(height: 4),
                Text('BMI is a screening baseline and does not directly gauge body fat percentage, lean muscle mass, or cellular energy reserves.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B), fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousRecord() {
    final bool wentDown = bmi > 0 && bmi < prevBmi;
    final double difference = bmi > 0 ? (bmi - prevBmi).abs() : 0.0;

    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFF8A3D).withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFF8A3D).withOpacity(0.3))), child: const Icon(Icons.history_rounded, size: 20, color: Color(0xFFFF8A3D))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Previous Record', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text('${prevBmi.toStringAsFixed(1)} on $prevDate', style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
              ],
            ),
          ),
          if (difference > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: wentDown ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFE91E8C).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text('${wentDown ? "-" : "+"}${difference.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: wentDown ? const Color(0xFF059669) : const Color(0xFFE91E8C), fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  const SizedBox(width: 2),
                  Icon(wentDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: wentDown ? const Color(0xFF059669) : const Color(0xFFE91E8C)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHolisticTip() {
    return _buildGlassCard(
      shadowColor: const Color(0xFF10B981).withOpacity(0.08),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Icon(Icons.tips_and_updates_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mindful Tip', style: TextStyle(fontSize: 14.5, color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                SizedBox(height: 4),
                Text('Balanced hydration and whole-food plant nutrients support cellular health far better than restriction.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF047857), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}