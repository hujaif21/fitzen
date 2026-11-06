import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'network/api_service.dart';

class WaterPage extends StatefulWidget {
  final String email;
  final double waterGoalML;

  const WaterPage({
    super.key,
    required this.email,
    required this.waterGoalML,
  });

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  // ============================================================
  // COLORS
  // ============================================================
  static const Color primaryTeal = Color(0xFF008B87);

  // ============================================================
  // DATA
  // ============================================================
  late String email;
  late double waterGoal;

  double waterConsumed = 0;
  double customAmount = 300;

  bool isLoading = true;
  bool isAdding = false;
  bool isDeleting = false;

  final List<WaterEntry> entries = [];

  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();
    email = widget.email.trim();
    waterGoal = widget.waterGoalML;
    _loadWaterData();
  }

  // ============================================================
  // LOAD WATER
  // ============================================================
  Future<void> _loadWaterData() async {
    try {
      waterGoal = widget.waterGoalML;

      if (email.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final date = _today();
      final response = await ApiService.postRequest({
        'action': 'getWater',
        'email': email,
        'date': date,
      });

      if (response['status'] == 'success') {
        waterConsumed = double.tryParse('${response['waterML'] ?? 0}') ?? 0;
        _rebuildTodayEntry();
      }
    } catch (e) {
      debugPrint('Water loading error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ============================================================
  // REBUILD TODAY ENTRY
  // ============================================================
  void _rebuildTodayEntry() {
    entries.clear();
    if (waterConsumed > 0) {
      entries.add(
        WaterEntry(
          id: _today(),
          title: "Today's Water",
          time: 'Today',
          amount: waterConsumed,
        ),
      );
    }
  }

  // ============================================================
  // ADD WATER
  // ============================================================
  Future<void> _addWater(double amount) async {
    if (amount <= 0 || isAdding) return;
    if (email.isEmpty) {
      _showMessage('User email not found', isError: true);
      return;
    }

    if (mounted) setState(() => isAdding = true);

    try {
      final date = _today();
      final response = await ApiService.postRequest({
        'action': 'addWater',
        'email': email,
        'date': date,
        'amountML': amount,
      });

      if (response['status'] == 'success') {
        if (mounted) {
          setState(() {
            waterConsumed += amount;
            _rebuildTodayEntry();
            isAdding = false;
          });
        }
        _showMessage('${_formatAmount(amount)} added', isError: false);
        return;
      } else {
        _showMessage(response['message']?.toString() ?? 'Unable to add water', isError: true);
      }
    } catch (e) {
      debugPrint('Add water error: $e');
      _showMessage('Something went wrong', isError: true);
    }

    if (mounted) setState(() => isAdding = false);
  }

  // ============================================================
  // DELETE WATER
  // ============================================================
  Future<void> _deleteWater(WaterEntry entry) async {
    if (email.isEmpty || isDeleting) return;

    if (mounted) setState(() => isDeleting = true);

    try {
      final response = await ApiService.postRequest({
        'action': 'deleteWater',
        'email': email,
        'date': _today(),
        'amountML': entry.amount,
      });

      if (response['status'] == 'success') {
        await _loadWaterData();
        _showMessage('Water entry deleted', isError: false);
      } else {
        _showMessage(response['message']?.toString() ?? 'Unable to delete entry', isError: true);
      }
    } catch (e) {
      debugPrint('Delete water error: $e');
      _showMessage('Unable to delete entry', isError: true);
    } finally {
      if (mounted) setState(() => isDeleting = false);
    }
  }

  // ============================================================
  // HELPERS (Math fixes applied)
  // ============================================================
  String _today() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$day/$month/${now.year}';
  }

  String _displayDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]}';
  }

  String _formatAmount(double ml) {
    if (ml >= 1000) {
      final liters = ml / 1000;
      if (liters == liters.roundToDouble()) return '${liters.toInt()} L';
      return '${liters.toStringAsFixed(1)} L';
    }
    return '${ml.toInt()} ml';
  }

  double get progress {
    if (waterGoal <= 0) return 0;
    return (waterConsumed / waterGoal).clamp(0.0, 1.0);
  }

  int get percentage => (progress * 100).round();

  double get remaining {
    final value = waterGoal - waterConsumed;
    return value < 0 ? 0 : value;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Match theme background
        body: Stack(
          children: [
            // 1. Premium Aurora Mesh Background
            _buildAuroraBackground(),

            // 2. Main Content
            SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                  : RefreshIndicator(
                color: primaryTeal,
                backgroundColor: Colors.white,
                onRefresh: _loadWaterData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      _buildDateGoalRow(),
                      const SizedBox(height: 16),
                      _buildHydrationCard(),
                      const SizedBox(height: 32),
                      _buildQuickAddTitle(),
                      const SizedBox(height: 16),
                      _buildQuickAddGrid(),
                      const SizedBox(height: 32),
                      _buildCustomAmountCard(),
                      const SizedBox(height: 32),
                      _buildTodayLog(),
                      const SizedBox(height: 24),
                      _buildHydrationTip(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

  // ============================================================
  // TOP BAR
  // ============================================================
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, true),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF26C6DA), Color(0xFF008B87)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hydration", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.3)),
              Text("Daily Water Intake", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_rounded, size: 14, color: primaryTeal),
              const SizedBox(width: 4),
              Text('$percentage%', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: primaryTeal)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE + GOAL
  // ============================================================
  Widget _buildDateGoalRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: primaryTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Today • ${_displayDate()}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFFF8A3D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Goal: ${_formatAmount(waterGoal)}', style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF334155), fontSize: 12.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HYDRATION CARD
  // ============================================================
  Widget _buildHydrationCard() {
    return _buildGlassCard(
      shadowColor: const Color(0xFF008B87).withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('HYDRATION VITALITY', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF008B87))),
                  SizedBox(height: 2),
                  Text("Today's Water", style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.4)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: percentage >= 100 ? const Color(0xFFE9F7EE) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: percentage >= 100 ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: percentage >= 100 ? const Color(0xFF059669) : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      percentage >= 100 ? 'Goal Reached!' : 'Tracking',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: percentage >= 100 ? const Color(0xFF065F46) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(child: _buildWaterCircle()),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildProgressInfo(
                  icon: Icons.pie_chart_rounded,
                  title: 'Progress',
                  value: '$percentage%',
                  subtitle: 'Target achieved',
                  gradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
                  accentColor: const Color(0xFF008B87),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressInfo(
                  icon: Icons.water_drop_outlined,
                  title: 'Remaining',
                  value: _formatAmount(remaining),
                  subtitle: remaining <= 0 ? 'All done!' : 'To complete',
                  gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                  accentColor: const Color(0xFFE91E8C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WATER CIRCLE
  // ============================================================
  Widget _buildWaterCircle() {
    return SizedBox(
      width: 200, // Slightly scaled down to prevent overflow
      height: 200,
      child: CustomPaint(
        painter: WaterCirclePainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop_rounded, color: primaryTeal, size: 24),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatAmount(waterConsumed),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1E293B)),
                ),
              ),
              Text(
                'Goal: ${_formatAmount(waterGoal)}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS INFO
  // ============================================================
  Widget _buildProgressInfo({required IconData icon, required String title, required String value, required String subtitle, required List<Color> gradient, required Color accentColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: gradient[1].withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gradient[1].withOpacity(0.2)),
            ),
            child: Icon(icon, color: gradient[1], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.3))),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ADD GRID
  // ============================================================
  Widget _buildQuickAddTitle() {
    return Row(
      children: [
        const Text("Quick Add", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white)),
          child: const Text('One-tap intake', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: primaryTeal, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildQuickAddGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _quickAddButton(amount: 250, icon: Icons.local_drink_rounded, subtitle: 'Standard Glass'),
        _quickAddButton(amount: 500, icon: Icons.local_drink_rounded, subtitle: 'Small Bottle'),
        _quickAddButton(amount: 750, icon: Icons.sports_bar_rounded, subtitle: 'Sports Flask'),
        _quickAddButton(amount: 1000, icon: Icons.water_damage_rounded, subtitle: 'Large Carafe'),
      ],
    );
  }

  Widget _quickAddButton({required double amount, required IconData icon, required String subtitle}) {
    return GestureDetector(
      onTap: isAdding ? null : () => _addWater(amount),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB2EBF2)),
                  ),
                  child: Icon(icon, color: primaryTeal, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('+${_formatAmount(amount)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM AMOUNT
  // ============================================================
  Widget _buildCustomAmountCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Custom Amount", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Row(
              children: [
                _amountControlButton(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(() => customAmount = math.max(50, customAmount - 50)),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          customAmount.toInt().toString(),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 4),
                        const Text('ml', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                _amountControlButton(
                  icon: Icons.add_rounded,
                  onTap: () => setState(() => customAmount += 50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF008B87)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF008B87).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: isAdding ? null : () => _addWater(customAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isAdding
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("Log This Intake", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountControlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1E293B)),
      ),
    );
  }

  // ============================================================
  // TODAY'S LOG
  // ============================================================
  Widget _buildTodayLog() {
    final total = entries.fold<double>(0, (sum, item) => sum + item.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Today's Log", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF1E293B))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
              child: Text(
                '${entries.length} ${entries.length == 1 ? "entry" : "entries"} • ${_formatAmount(total)}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          _buildGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFE0F7FA), shape: BoxShape.circle),
                  child: const Icon(Icons.water_drop_outlined, color: primaryTeal, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('No water logged yet today', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text('Tap a preset above to record hydration.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          ...entries.map((entry) => _buildWaterLogItem(entry)),
      ],
    );
  }

  Widget _buildWaterLogItem(WaterEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB2EBF2)),
            ),
            child: const Icon(Icons.water_drop_rounded, color: primaryTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(entry.time, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
            child: Text('+${_formatAmount(entry.amount)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: primaryTeal, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isDeleting ? null : () => _deleteWater(entry),
            splashRadius: 20,
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIP
  // ============================================================
  Widget _buildHydrationTip() {
    return _buildGlassCard(
      shadowColor: const Color(0xFF10B981).withOpacity(0.08),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mindful Hydration', style: TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                SizedBox(height: 4),
                Text('Consistent sipping boosts nutrient absorption and prevents metabolic fatigue during sustained focus.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.45, color: Color(0xFF047857), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WATER ENTRY MODEL
// ============================================================
class WaterEntry {
  final String id;
  final String title;
  final String time;
  final double amount;

  WaterEntry({
    required this.id,
    required this.title,
    required this.time,
    required this.amount,
  });
}

// ============================================================
// WATER CIRCLE PAINTER
// ============================================================
class WaterCirclePainter extends CustomPainter {
  final double progress;

  WaterCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8; // Fixed math error

    // Outer subtle track
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFFF1F5F9);

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweepAngle = (math.pi * 2 * progress).clamp(0.0, math.pi * 2); // Fixed math error

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2, // Fixed math error
          colors: [Color(0xFF26C6DA), Color(0xFF008B87)],
        ).createShader(rect);

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }

    // Water body
    final clampedProgress = progress.clamp(0.0, 1.0);
    final waterTop = size.height * (0.85 - clampedProgress * 0.70); // Fixed math error

    final waterPath = Path();
    waterPath.moveTo(0, waterTop);

    // Fixed math errors for drawing the wave
    waterPath.quadraticBezierTo(size.width * 0.25, waterTop + 6, size.width * 0.5, waterTop);
    waterPath.quadraticBezierTo(size.width * 0.75, waterTop - 6, size.width, waterTop);
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 3)));

    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4DD0E1), Color(0xFF00838F)],
      ).createShader(Rect.fromLTWH(0, waterTop, size.width, size.height - waterTop)); // Fixed math error

    canvas.drawPath(waterPath, waterPaint);

    // Light water surface highlight
    final surfacePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE0F7FA).withOpacity(0.85);

    final surfacePath = Path();
    surfacePath.moveTo(0, waterTop);
    // Fixed math errors for drawing the surface wave
    surfacePath.quadraticBezierTo(size.width * 0.25, waterTop + 6, size.width * 0.5, waterTop);
    surfacePath.quadraticBezierTo(size.width * 0.75, waterTop - 6, size.width, waterTop);

    canvas.drawPath(surfacePath, surfacePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WaterCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}