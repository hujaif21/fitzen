import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'network/api_service.dart';
import 'scan_food.dart';

class AddFoodPage extends StatefulWidget {
  final String email;

  const AddFoodPage({
    super.key,
    required this.email,
  });

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController servingController = TextEditingController(text: "1.0");
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController(text: "0");
  final TextEditingController carbsController = TextEditingController(text: "0");
  final TextEditingController fatsController = TextEditingController(text: "0");

  // ============================================================
  // VARIABLES
  // ============================================================
  String selectedMeal = "Lunch";
  String selectedUnit = "Serving";

  bool manualExpanded = true;
  bool isLoading = false;

  @override
  void dispose() {
    foodNameController.dispose();
    servingController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatsController.dispose();
    super.dispose();
  }

  // ============================================================
  // ADD FOOD HANDLER
  // ============================================================
  Future<void> _addFood() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final foodName = foodNameController.text.trim();
    final caloriesText = caloriesController.text.trim();
    final quantityText = servingController.text.trim();
    final proteinText = proteinController.text.trim();
    final carbsText = carbsController.text.trim();
    final fatText = fatsController.text.trim();

    if (foodName.isEmpty) {
      _showMessage("Please enter Food Name.", isError: true);
      return;
    }

    if (quantityText.isEmpty) {
      _showMessage("Please enter Serving Size.", isError: true);
      return;
    }

    if (caloriesText.isEmpty) {
      _showMessage("Please enter Total Calories.", isError: true);
      return;
    }

    final quantity = double.tryParse(quantityText);
    final calories = double.tryParse(caloriesText);
    final protein = double.tryParse(proteinText) ?? 0;
    final carbs = double.tryParse(carbsText) ?? 0;
    final fat = double.tryParse(fatText) ?? 0;

    if (quantity == null || quantity <= 0) {
      _showMessage("Please enter a valid Serving Size.", isError: true);
      return;
    }

    if (calories == null || calories < 0) {
      _showMessage("Please enter valid Calories.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.addFood(
        email: widget.email,
        mealType: selectedMeal,
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        quantity: quantity,
        unit: selectedUnit,
      );

      if (!mounted) return;

      final status = response["status"]?.toString().toLowerCase();

      if (status == "success") {
        _showMessage(response["message"]?.toString() ?? "$foodName added successfully.", isError: false);
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        Navigator.pop(context, true); // Returns true to trigger Home refresh
      } else {
        _showMessage(response["message"]?.toString() ?? "Failed to add food.", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage("Unable to add food. Please try again.", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
      backgroundColor: const Color(0xFFF1F5F9), // Match home screen background
      body: Stack(
        children: [
          // 1. Premium Aurora Mesh Background
          _buildAuroraBackground(),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
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
                          "Add Food",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "How would you like to log your nourishment?",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),

                        // Option 1: AI Vision Scan
                        _buildGlassOptionCard(
                          icon: Icons.document_scanner_rounded,
                          iconGradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                          title: "Scan Plate",
                          subtitle: "Estimate portions instantly...",
                          badge: "AI VISION",
                          trailing: Icons.arrow_forward_ios_rounded,
                          onTap: () async {
                            final foodLogged = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanFoodPage()));
                            if (foodLogged == true && mounted) {
                              Navigator.pop(context, true); // Close and refresh home
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Option 2: Manual Entry Toggle
                        _buildGlassOptionCard(
                          icon: Icons.edit_note_rounded,
                          iconGradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
                          title: "Manual Entry",
                          subtitle: "Log micro & macros precisely...",
                          trailing: manualExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          selected: manualExpanded,
                          onTap: () => setState(() => manualExpanded = !manualExpanded),
                        ),

                        // Form
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: manualExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _buildManualEntryForm(),
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 32),
                        _buildMindfulTip(),
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

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Log Nourishment",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
            ),
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
          const Text("DAILY TRACKER", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFE91E8C), fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildGlassOptionCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
    String? badge,
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shadowColor: selected ? iconGradient[1].withOpacity(0.15) : null,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconGradient[1].withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: iconGradient[1].withOpacity(0.3)),
              ),
              child: Icon(icon, color: iconGradient[1], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins', letterSpacing: 0.5)),
              ),
            Icon(trailing, color: const Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MANUAL ENTRY FORM
  // ============================================================
  Widget _buildManualEntryForm() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Quick Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                    SizedBox(height: 4),
                    Text("Fill in nutritional values manually", style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white),
                ),
                child: const Icon(Icons.local_dining_rounded, color: Color(0xFFE91E8C), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildLabel(title: "Food Name", required: true),
          const SizedBox(height: 8),
          _buildTextField(controller: foodNameController, hint: "e.g., Avocado Toast", icon: Icons.restaurant_rounded),
          const SizedBox(height: 20),

          _buildLabel(title: "Meal Type", required: true),
          const SizedBox(height: 8),
          _buildMealSelector(),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(title: "Serving Size", required: true),
                    const SizedBox(height: 8),
                    _buildTextField(controller: servingController, hint: "1.0", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(title: "Unit", required: true),
                    const SizedBox(height: 8),
                    _buildUnitDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildLabel(title: "Total Calories", required: true, trailing: "kcal"),
          const SizedBox(height: 8),
          _buildTextField(controller: caloriesController, hint: "e.g., 340", keyboardType: const TextInputType.numberWithOptions(decimal: true), icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFFFF8A3D)),
          const SizedBox(height: 28),

          const Text("Macronutrients (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          const Text("Values in grams", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Poppins')),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildMacroField(label: "Protein", color: const Color(0xFFE91E8C), controller: proteinController)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroField(label: "Carbs", color: const Color(0xFFFF8A3D), controller: carbsController)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroField(label: "Fats", color: const Color(0xFF10B981), controller: fatsController)),
            ],
          ),
          const SizedBox(height: 32),

          // Gradient Add Button
          SizedBox(
            height: 56,
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _addFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("Add to Diary", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM COMPONENTS
  // ============================================================
  Widget _buildLabel({required String title, bool required = false, String? trailing}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155), fontFamily: 'Poppins')),
        if (required) const Text(" *", style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.w700, fontSize: 13)),
        const Spacer(),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, IconData? icon, Color iconColor = const Color(0xFF94A3B8), TextInputType? keyboardType}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: iconColor) : null,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _buildMealSelector() {
    final meals = ["Breakfast", "Lunch", "Snack", "Dinner"]; // Updated to match Home data flow

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: meals.map((meal) {
          final selected = selectedMeal == meal;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedMeal = meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    meal,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFFE91E8C) : const Color(0xFF64748B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedUnit,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF94A3B8)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: "Serving", child: Text("Serving")),
            DropdownMenuItem(value: "100g", child: Text("100g")),
            DropdownMenuItem(value: "Gram", child: Text("Gram")),
            DropdownMenuItem(value: "Piece", child: Text("Piece")),
            DropdownMenuItem(value: "Cup", child: Text("Cup")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedUnit = value);
          },
        ),
      ),
    );
  }

  Widget _buildMacroField({required String label, required Color color, required TextEditingController controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: "0", hintStyle: TextStyle(color: Color(0xFFCBD5E1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMindfulTip() {
    return _buildGlassCard(
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
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mindful Tip', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'Poppins')),
                SizedBox(height: 4),
                Text('Take 3 deep breaths before mealtimes to aid digestion and focus.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B), fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}