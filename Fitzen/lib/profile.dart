import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'home.dart';
import 'progress.dart';
import 'edit_profile.dart';
import 'activity_stream.dart';
import 'setting.dart';
import 'core_settings.dart'; // 🚨 Integrated for dynamic themes & AppColors
import 'login.dart';
import 'network/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;

  String fullName = "User";
  String email = "";
  String gender = "--";
  String dob = "--";
  String weight = "0.0 kg";
  String height = "--";
  String goal = "--";

  double bmi = 0.0;
  int calorieGoal = 0;
  int caloriesLogged = 0;
  double waterGoal = 0.0;
  double waterConsumed = 0.0;
  int activeStreak = 0;

  Uint8List? profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      if (userEmail.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final response = await ApiService.getProfile(userEmail);

      final savedImageBase64 = prefs.getString('profileImageBase64');
      if (savedImageBase64 != null && savedImageBase64.isNotEmpty) {
        setState(() => profileImageBytes = base64Decode(savedImageBase64));
      }

      final localName = prefs.getString('savedUserName') ?? '';

      if (response['status'] == 'success') {
        final data = response['data'] ?? {};

        setState(() {
          email = data['email'] ?? userEmail;

          if (localName.isNotEmpty) {
            fullName = localName;
          } else {
            fullName = data['fullName'] ?? email.split('@')[0];
          }

          gender = data['gender'] ?? '--';
          dob = data['dob'] ?? '--';
          goal = data['goal'] ?? '--';

          final currentWeight = (data['currentWeight'] as num?)?.toDouble() ?? 0.0;
          weight = "${currentWeight.toStringAsFixed(1)} kg";

          final currentHeight = (data['currentHeight'] as num?)?.toDouble() ?? 0.0;
          height = currentHeight > 0 ? "${currentHeight.toStringAsFixed(1)} cm" : "Not set";

          calorieGoal = (data['calorieGoal'] as num?)?.toInt() ?? 0;
          caloriesLogged = (data['caloriesLogged'] as num?)?.toInt() ?? 0;
          waterGoal = (data['waterGoalLiters'] as num?)?.toDouble() ?? 0.0;
          waterConsumed = (data['waterConsumedLiters'] as num?)?.toDouble() ?? 0.0;
          activeStreak = (data['activeStreak'] as num?)?.toInt() ?? 0;

          final savedHeight = prefs.getString('userHeight') ?? '';
          if (savedHeight.isNotEmpty && currentWeight > 0) {
            final heightCm = double.tryParse(savedHeight);
            if (heightCm != null && heightCm > 0) {
              final heightM = heightCm / 100;
              bmi = currentWeight / (heightM * heightM);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          profileImageBytes = bytes;
        });

        final base64String = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageBase64', base64String);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
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
              _buildAuroraBackground(context),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE91E8C),
                        ),
                      )
                          : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileHeader(context),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              context,
                              icon: Icons.auto_graph_rounded,
                              title: "Your Stats",
                              trailing: "Updated today",
                              gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                            ),
                            const SizedBox(height: 12),
                            _buildStatsGrid(context),
                            const SizedBox(height: 12),
                            _buildStreakCard(context),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              context,
                              icon: Icons.badge_outlined,
                              title: "Personal Information",
                              trailing: "Tap to edit",
                              trailingColor: const Color(0xFFE91E8C),
                              gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            const SizedBox(height: 12),
                            _buildPersonalInformation(context),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              context,
                              icon: Icons.grid_view_rounded,
                              title: "Account & Preferences",
                              gradient: const [Color(0xFF00ACC1), Color(0xFF008B87)],
                            ),
                            const SizedBox(height: 12),
                            _buildAccountOptions(context),
                            const SizedBox(height: 26),
                            _buildLogoutButton(context),
                            const SizedBox(height: 16),
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
              child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary(context)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Profile",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "FitZen Member",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FitzenSettingsScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.settings_outlined, size: 20, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 106,
                  height: 106,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E8C).withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: CircleAvatar(
                      backgroundColor: AppColors.isDark(context) ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      backgroundImage: profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
                      child: profileImageBytes == null
                          ? Icon(Icons.person_rounded, size: 48, color: AppColors.textSecondary(context))
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E8C).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName.toUpperCase(),
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12.5,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  if (updated == true) _loadProfileData();
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E8C).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 15, color: Colors.white),
                      SizedBox(width: 7),
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FitzenSettingsScreen()),
                  );
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 15, color: AppColors.textPrimary(context)),
                      const SizedBox(width: 6),
                      Text(
                        "Preferences",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? trailing,
        Color? trailingColor,
        required List<Color> gradient,
      }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradient[0].withOpacity(0.18), gradient[1].withOpacity(0.18)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: gradient[1]),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary(context),
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: trailingColor ?? AppColors.textSecondary(context),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _statCard(
          context,
          title: "Weight",
          value: weight.replaceAll(" kg", ""),
          unit: "kg",
          icon: Icons.monitor_weight_rounded,
          gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          bottom: "Current weight",
          bottomColor: const Color(0xFF10B981),
        ),
        _statCard(
          context,
          title: "BMI Score",
          value: bmi > 0 ? bmi.toStringAsFixed(1) : "--",
          unit: "",
          icon: Icons.speed_rounded,
          gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
          bottom: bmi > 0 ? "Calculated" : "Set in BMI page",
          bottomColor: const Color(0xFF7C3AED),
          pill: bmi > 0,
        ),
        _statCard(
          context,
          title: "Calorie Goal",
          value: calorieGoal.toStringAsFixed(0),
          unit: "kcal",
          icon: Icons.local_fire_department_rounded,
          gradient: const [Color(0xFFFF7E8B), Color(0xFFE91E8C)],
          bottom: "$caloriesLogged logged today",
          bottomColor: AppColors.textSecondary(context),
          progress: calorieGoal > 0 ? (caloriesLogged / calorieGoal).clamp(0.0, 1.0) : 0.0,
        ),
        _statCard(
          context,
          title: "Hydration",
          value: waterGoal.toStringAsFixed(1),
          unit: "L",
          icon: Icons.water_drop_rounded,
          gradient: const [Color(0xFF26C6DA), Color(0xFF008B87)],
          bottom: "${waterConsumed.toStringAsFixed(1)} L consumed",
          bottomColor: AppColors.textSecondary(context),
          progress: waterGoal > 0 ? (waterConsumed / waterGoal).clamp(0.0, 1.0) : 0.0,
        ),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, {
        required String title,
        required String value,
        required String unit,
        required IconData icon,
        required List<Color> gradient,
        required String bottom,
        required Color bottomColor,
        bool pill = false,
        double? progress,
      }) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradient[0].withOpacity(0.18), gradient[1].withOpacity(0.18)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: gradient[1]),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
          if (pill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bottom,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            )
          else ...[
            if (progress != null) ...[
              Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
            Text(
              bottom,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: bottomColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadowColor: const Color(0xFFFF8A3D).withOpacity(0.06),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3EB), Color(0xFFFFE8D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF8A3D).withOpacity(0.3)),
            ),
            child: const Center(child: Text("🔥", style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Active Streak",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$activeStreak Days",
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 9.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Mindful nutrition and workout logged consecutively",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textSecondary(context)),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          _infoRow(context, "Full Name", fullName.toUpperCase()),
          _divider(context),
          _infoRow(context, "Email Address", email),
          _divider(context),
          _infoRow(context, "Gender", gender),
          _divider(context),
          _infoRow(context, "Date of Birth", dob),
          _divider(context),
          _infoRow(context, "Current Weight", weight),
          _divider(context),
          _infoRow(context, "Current Height", height),
          _divider(context),
          _goalRow(context),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Primary Goal",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9F7EE), Color(0xFFD1FAE5)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                const SizedBox(width: 4),
                Text(
                  goal,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11.5,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, thickness: 0.8, color: AppColors.border(context));
  }

  Widget _buildAccountOptions(BuildContext context) {
    return _buildGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          _accountOption(
            context,
            icon: Icons.person_outline_rounded,
            title: "Edit Profile",
            subtitle: "Update personal metrics & goals",
            gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              if (updated == true) _loadProfileData();
            },
          ),
          _accountDivider(context),
          _accountOption(
            context,
            icon: Icons.notifications_none_rounded,
            title: "Notifications & Activity",
            subtitle: "Reminders for meals & hydration",
            badge: "2",
            badgeColor: const Color(0xFFE91E8C),
            gradient: const [Color(0xFF00ACC1), Color(0xFF008B87)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivityStreamScreen()),
              );
            },
          ),
          _accountDivider(context),
          _accountOption(
            context,
            icon: Icons.tune_rounded,
            title: "Settings & Preferences",
            subtitle: "Theme, units, language & data export",
            gradient: const [Color(0xFF64748B), Color(0xFF334155)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FitzenSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _accountOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required List<Color> gradient,
        String? badge,
        Color? badgeColor,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradient[0].withOpacity(0.15), gradient[1].withOpacity(0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: gradient[1]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF7C3AED)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? const Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _accountDivider(BuildContext context) => Divider(height: 1, thickness: 0.8, color: AppColors.border(context), indent: 56);

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCD3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutDialog(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 19, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                "Log Out of FitZen",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            "Log Out?",
            style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary(context)),
          ),
          content: Text(
            "Are you sure you want to log out of your FitZen account?",
            style: TextStyle(fontFamily: "Poppins", fontSize: 13, color: AppColors.textSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const FitZenSignInScreen()),
                        (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Log Out", style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

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
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
                child: const _NavItem(icon: Icons.home_rounded, label: "Home", active: false),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProgressPage())),
                child: const _NavItem(icon: Icons.trending_up_rounded, label: "Progress", active: false),
              ),
              const _NavItem(icon: Icons.person_rounded, label: "Profile", active: true),
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