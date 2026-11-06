import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:fitzen/home.dart';
import 'package:fitzen/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  bool isLoading = true;
  String userEmail = '';

  double currentWeight = 0.0;
  double startingWeight = 0.0;
  double goalWeight = 65.0;
  String userGoal = 'Weight Loss';

  List<Map<String, dynamic>> weightHistory = [];

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      if (userEmail.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final profileResponse = await ApiService.getProfile(userEmail);
      if (profileResponse['status'] == 'success' && profileResponse['profile'] != null) {
        final profile = profileResponse['profile'];
        userGoal = profile['goal']?.toString() ?? 'Weight Loss';
        final double heightCm = double.tryParse(profile['height']?.toString() ?? '170') ?? 170.0;
        final double profileWeight = double.tryParse(profile['weight']?.toString() ?? '70') ?? 70.0;

        final double heightM = heightCm / 100.0;
        final double idealBmiWeight = 22.0 * (heightM * heightM); // Fixed Math

        if (userGoal.toLowerCase().contains('loss') || userGoal.toLowerCase().contains('fat')) {
          goalWeight = idealBmiWeight < profileWeight ? idealBmiWeight : (profileWeight - 5.0);
        } else if (userGoal.toLowerCase().contains('gain') || userGoal.toLowerCase().contains('muscle')) {
          goalWeight = idealBmiWeight > profileWeight ? idealBmiWeight : (profileWeight + 5.0);
        } else {
          goalWeight = profileWeight;
        }
        goalWeight = double.parse(goalWeight.toStringAsFixed(1));
      }

      final response = await ApiService.getWeightLogs(userEmail);

      if (response['status'] == 'success') {
        final logs = List<Map<String, dynamic>>.from(response['logs'] ?? []);

        setState(() {
          startingWeight = double.tryParse(response['startingWeight'].toString()) ?? 65.0;

          if (logs.isNotEmpty) {
            currentWeight = double.parse(logs.last['weight'].toString());
            weightHistory = logs.reversed.toList();
          } else {
            currentWeight = startingWeight;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading weights: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGainingWeight = goalWeight > startingWeight;
    final double totalChangeNeeded = (goalWeight - startingWeight).abs(); // Fixed Math

    final double currentChange = isGainingWeight
        ? (currentWeight - startingWeight) // Fixed Math
        : (startingWeight - currentWeight); // Fixed Math

    final double progress = totalChangeNeeded > 0
        ? (currentChange / totalChangeNeeded).clamp(0.0, 1.0)
        : 1.0;

    final double remainingToTarget = (goalWeight - currentWeight).abs(); // Fixed Math
    final String changeLabel = isGainingWeight ? 'total gain' : 'total loss';

    // Aurora Theme Colors for Trends
    final Color trendColor = isGainingWeight && currentChange > 0
        ? const Color(0xFF10B981) // Mint
        : !isGainingWeight && currentChange > 0
        ? const Color(0xFF10B981) // Mint
        : const Color(0xFFE91E8C); // Pink

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Match theme background
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
                          "Body Composition",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Goal: $userGoal • Monitor weight trends',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),

                        _buildCurrentWeightCard(progress, currentChange, remainingToTarget, changeLabel, trendColor, isGainingWeight),
                        const SizedBox(height: 24),

                        // Premium Log Button
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
                              onPressed: _showLogWeightDialog,
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.white),
                              label: const Text('Log Weight', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Text('Progress (Last 30 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white)),
                              child: Text(
                                  isGainingWeight ? 'Growth' : 'Decline',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF008B87), fontWeight: FontWeight.w700, fontFamily: 'Poppins')
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildWeightChart(),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Expanded(
                              child: Text('Weight History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                            ),
                            Text('${weightHistory.length} records', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (weightHistory.isEmpty)
                          _buildGlassCard(
                            padding: const EdgeInsets.all(24),
                            child: const Center(
                              child: Text('No weight history logged yet.', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Poppins')),
                            ),
                          )
                        else
                          ...weightHistory.map((log) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildHistoryCard(
                                date: log['date'].toString(),
                                weight: double.parse(log['weight'].toString()).toStringAsFixed(1),
                                description: 'Logged entry',
                                change: 'Recorded',
                                onDelete: () => _deleteWeightLog(
                                    log['date'].toString(),
                                    double.parse(log['weight'].toString())
                                ),
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 24),
                        _buildPrivacyCard(),
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
        Positioned(
          top: -50,
          right: -50,
          child: Container(width: 350, height: 350, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x30FF8A3D))),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x3000ACC1))),
        ),
        Positioned.fill(
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
        ),
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
          const Text("TRENDS & DATA", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFE91E8C), fontFamily: 'Poppins')),
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
            child: const Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Weight Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
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

  Widget _buildCurrentWeightCard(double progress, double currentChange, double remainingToTarget, String changeLabel, Color trendColor, bool isGainingWeight) {
    return _buildGlassCard(
      shadowColor: const Color(0xFFE91E8C).withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE91E8C).withOpacity(0.25)),
                ),
                child: const Icon(Icons.monitor_weight_rounded, size: 20, color: Color(0xFFE91E8C)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Current Weight', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
                child: const Text('Updated Today', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currentWeight.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
                ),
                const SizedBox(width: 4),
                const Text('kg', style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: trendColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(
                          currentChange >= 0
                              ? (isGainingWeight ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                              : (isGainingWeight ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                          color: trendColor,
                          size: 16
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentChange > 0 ? "+" : ""}${currentChange.toStringAsFixed(1)} kg $changeLabel',
                        style: TextStyle(fontSize: 12, color: trendColor, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  const Text('Smart Target:', style: TextStyle(fontSize: 13, color: Color(0xFF334155), fontFamily: 'Poppins')),
                  Text(' ${goalWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                  const SizedBox(width: 12),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text('${remainingToTarget.toStringAsFixed(1)} kg to go', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text('Start: ${startingWeight.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600))),
              Flexible(child: Text('${(progress * 100).round()}% Completed', style: const TextStyle(fontSize: 11, color: Color(0xFFE91E8C), fontWeight: FontWeight.w800, fontFamily: 'Poppins'))),
              Flexible(child: Text('Goal: ${goalWeight.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    List<double> chartWeights = [];
    if (weightHistory.isEmpty) {
      chartWeights = [startingWeight, startingWeight];
    } else {
      chartWeights = weightHistory.take(4).map((e) => double.parse(e['weight'].toString())).toList().reversed.toList();
      if (chartWeights.length < 2) chartWeights.insert(0, startingWeight);
    }

    final double allTimeLow = [goalWeight, ...chartWeights].reduce(math.min) - 2;
    final double allTimeHigh = [goalWeight, ...chartWeights].reduce(math.max) + 2;

    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('History', style: TextStyle(fontSize: 10, color: Color(0xFF334155), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF26C6DA), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Projected', style: TextStyle(fontSize: 10, color: Color(0xFF334155), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 220,
            child: CustomPaint(
              painter: _WeightChartPainter(
                weights: chartWeights,
                goalWeight: goalWeight,
                minBound: allTimeLow,
                maxBound: allTimeHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({required String date, required String weight, required String description, required String change, required VoidCallback onDelete}) {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A3D).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF8A3D).withOpacity(0.3)),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF8A3D), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontFamily: 'Poppins')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(weight, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                  const SizedBox(width: 2),
                  const Text('kg', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(change, style: const TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return _buildGlassCard(
      shadowColor: const Color(0xFF26C6DA).withOpacity(0.08),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.lock_outline_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Weight data is encrypted and used solely for metabolic calculations.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155), fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogWeightDialog() {
    final TextEditingController controller = TextEditingController(text: currentWeight.toStringAsFixed(1));
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('Log Weight', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: Color(0xFF1E293B))),
                content: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: Color(0xFF1E293B)),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      labelStyle: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      final double? newWeight = double.tryParse(controller.text);
                      if (newWeight == null || newWeight <= 0) return;

                      setDialogState(() => isSaving = true);

                      try {
                        final response = await ApiService.logWeight(userEmail, newWeight);
                        if (response['status'] == 'success') {
                          if (mounted) Navigator.pop(context);
                          _loadWeightData();
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: const Text('Weight logged', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: const Text('Failed to log weight', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFFE91E8C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E8C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isSaving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _deleteWeightLog(String date, double weight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Log', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: Color(0xFF1E293B))),
        content: Text('Delete the $weight kg record from $date?', style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                final response = await ApiService.deleteWeight(userEmail, date, weight);
                if (response['status'] == 'success') {
                  _loadWeightData();
                  if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: const Text('Log deleted', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } else {
                  setState(() => isLoading = false);
                  if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: const Text('Failed to delete', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFFE91E8C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                }
              } catch (e) {
                setState(() => isLoading = false);
                if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: const Text('Error deleting log', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFFE91E8C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E8C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final double goalWeight;
  final double minBound;
  final double maxBound;

  _WeightChartPainter({
    required this.weights,
    required this.goalWeight,
    required this.minBound,
    required this.maxBound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    final Paint gridPaint = Paint()..color = Colors.white.withOpacity(0.6)..strokeWidth = 1;

    // Aurora colors
    final Paint linePaint = Paint()..color = const Color(0xFFE91E8C)..strokeWidth = 3..style = PaintingStyle.stroke;
    final Paint lineFillPaint = Paint()..color = const Color(0xFFE91E8C).withOpacity(0.15)..style = PaintingStyle.fill;
    final Paint projectedPaint = Paint()..color = const Color(0xFF26C6DA)..strokeWidth = 2.5..style = PaintingStyle.stroke;

    final double left = 38;
    final double right = size.width - 12; // Fixed Math
    final double top = 20;
    final double bottom = size.height - 30; // Fixed Math

    final double midLevel = (maxBound + minBound) / 2;
    final List<double> levels = [maxBound, midLevel, minBound];

    // Draw Grid and Y-Axis Labels
    for (final level in levels) {
      final double y = _mapY(level, top, bottom);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      final textPainter = TextPainter(text: TextSpan(text: '${level.toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Poppins', fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Target Line (Mint)
    final double targetY = _mapY(goalWeight, top, bottom);
    final Paint targetPaint = Paint()..color = const Color(0xFF10B981)..strokeWidth = 1.5;
    for (double x = left; x < right; x += 8) {
      canvas.drawLine(Offset(x, targetY), Offset(x + 4, targetY), targetPaint);
    }
    final targetText = TextPainter(text: TextSpan(text: 'Target', style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontFamily: 'Poppins', fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr);
    targetText.layout();
    targetText.paint(canvas, Offset(right - targetText.width, targetY - 14));

    // Calculate Points
    final double chartWidth = right - left;
    final double step = chartWidth / (weights.length - 1 > 0 ? weights.length - 1 : 1); // Fixed Math
    final List<Offset> points = [];

    for (int i = 0; i < weights.length; i++) {
      points.add(Offset(left + step * i, _mapY(weights[i], top, bottom)));
    }

    // Draw History Line and Fill
    if (points.length > 1) {
      final Path fillPath = Path()..moveTo(points.first.dx, bottom);
      for (final point in points) fillPath.lineTo(point.dx, point.dy);
      fillPath.lineTo(points.last.dx, bottom);
      fillPath.close();
      canvas.drawPath(fillPath, lineFillPaint);

      final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) linePath.lineTo(points[i].dx, points[i].dy);
      canvas.drawPath(linePath, linePaint);
    }

    // Draw Data Points
    final Paint pointPaint = Paint()..color = const Color(0xFFE91E8C)..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }

    // Projected Line (Cyan)
    final Offset projectedStart = points.last;
    final Offset projectedEnd = Offset(right, targetY);
    final double projectedDx = projectedEnd.dx - projectedStart.dx; // Fixed Math
    final double projectedDy = projectedEnd.dy - projectedStart.dy; // Fixed Math
    final double distance = projectedDx.abs() + projectedDy.abs();

    if (distance > 0) {
      for (double d = 0; d < distance; d += 10) {
        final double ratio = d / distance;
        final Offset start = Offset(projectedStart.dx + projectedDx * ratio, projectedStart.dy + projectedDy * ratio);
        final Offset end = Offset(projectedStart.dx + projectedDx * (ratio + 0.035).clamp(0.0, 1.0), projectedStart.dy + projectedDy * (ratio + 0.035).clamp(0.0, 1.0));
        canvas.drawLine(start, end, projectedPaint);
      }
    }

    canvas.drawCircle(projectedEnd, 5, Paint()..color = const Color(0xFF26C6DA));
    canvas.drawCircle(projectedEnd, 2, Paint()..color = Colors.white);

    // Current Weight Label
    final Offset currentPoint = points.last;
    final Rect labelRect = Rect.fromCenter(center: Offset(currentPoint.dx, currentPoint.dy - 24), width: 56, height: 26); // Fixed Math
    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(8)), Paint()..color = const Color(0xFF1E293B));
    final currentText = TextPainter(text: TextSpan(text: '${weights.last.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins')), textDirection: TextDirection.ltr);
    currentText.layout();
    currentText.paint(canvas, Offset(labelRect.center.dx - currentText.width / 2, labelRect.center.dy - currentText.height / 2)); // Fixed Math
  }

  double _mapY(double weight, double top, double bottom) {
    final double normalized = (weight - minBound) / (maxBound - minBound); // Fixed Math
    return bottom - normalized * (bottom - top);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => true;
}