import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui'; // Required for Glassmorphism ImageFilter
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String selectedGender = 'Male';
  String selectedGoal = 'Lose Weight';

  Uint8List? profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  final List<String> goalOptions = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Muscle',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProfile() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';
      _emailController.text = userEmail;

      // Load locally stored image
      final savedImageBase64 = prefs.getString('profileImageBase64');
      if (savedImageBase64 != null && savedImageBase64.isNotEmpty) {
        profileImageBytes = base64Decode(savedImageBase64);
      }

      if (userEmail.isNotEmpty) {
        final response = await ApiService.getProfile(userEmail);
        if (response['status'] == 'success') {
          final data = response['data'] ?? {};
          _fullNameController.text = data['fullName'] ?? userEmail.split('@')[0];

          final g = data['gender']?.toString().trim() ?? 'Male';
          selectedGender = (g == 'Male' || g == 'Female' || g == 'Others') ? g : 'Male';

          _dobController.text = data['dob']?.toString() ?? '21/04/2007';

          final currentWeight = (data['currentWeight'] as num?)?.toDouble() ?? 60.0;
          _weightController.text = currentWeight.toStringAsFixed(1);

          final currentHeight = (data['currentHeight'] as num?)?.toDouble() ?? 0.0;
          _heightController.text = currentHeight > 0 ? currentHeight.toStringAsFixed(1) : '';

          final loadedGoal = data['goal']?.toString().trim() ?? 'Lose Weight';
          selectedGoal = goalOptions.contains(loadedGoal) ? loadedGoal : 'Lose Weight';
        }
      }
    } catch (e) {
      debugPrint("Error loading profile for edit: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // PHOTO PICKER ACTIONS
  // ============================================================
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

  Future<void> _removeImage() async {
    setState(() {
      profileImageBytes = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profileImageBase64');
  }

  // ============================================================
  // DATE PICKER
  // ============================================================
  Future<void> _selectDate() async {
    DateTime initialDate = DateTime(2005, 1, 1);
    try {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E8C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      setState(() {
        _dobController.text = "$d/$m/$y";
      });
    }
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================
  Future<void> _saveChanges() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    final height = double.tryParse(_heightController.text);
    if (height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid height')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final response = await ApiService.updateProfile(
        email: _emailController.text,
        fullName: _fullNameController.text,
        gender: selectedGender,
        dob: _dobController.text,
        weight: weight,
        height: height,
        goal: selectedGoal,
      );

      if (response['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedUserName', _fullNameController.text);
        await prefs.setString('userHeight', height.toString());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Failed to save.')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. FitZen Bioluminescent Aurora Background
          _buildAuroraBackground(),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
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
                          "Loading Edit Details...",
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrecisionBanner(),
                        const SizedBox(height: 20),

                        // Avatar Card Section
                        _buildGlassCard(
                          child: Column(
                            children: [
                              _buildProfileImage(),
                              const SizedBox(height: 16),
                              _buildPhotoActions(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Identity & Vitals Section Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitleHeader(
                                icon: Icons.person_outline_rounded,
                                title: "Identity & Personal Specs",
                                color: const Color(0xFFE91E8C),
                              ),
                              const SizedBox(height: 16),
                              _buildFullNameField(),
                              const SizedBox(height: 18),
                              _buildEmailField(),
                              const SizedBox(height: 18),
                              _buildGenderSelection(),
                              const SizedBox(height: 18),
                              _buildDateOfBirthField(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Metabolic Parameters Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitleHeader(
                                icon: Icons.monitor_weight_outlined,
                                title: "Body Metrics & Goals",
                                color: const Color(0xFF00ACC1),
                              ),
                              const SizedBox(height: 16),
                              _buildWeightField(),
                              const SizedBox(height: 18),
                              _buildHeightField(),
                              const SizedBox(height: 18),
                              _buildGoalField(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildCompletionBanner(),
                        const SizedBox(height: 26),

                        _buildSaveButton(),
                        const SizedBox(height: 14),
                        _buildDiscardButton(),
                        const SizedBox(height: 24),
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
  // FITZEN GLASS & AURORA UI HELPERS
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

  Widget _buildSectionTitleHeader({required IconData icon, required String title, required Color color}) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Update your metrics & preferences',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNERS
  // ============================================================
  Widget _buildPrecisionBanner() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF00ACC1), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Precision Status',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Baseline 98% Synchronized',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontFamily: "Poppins",
                color: Color(0xFF059669),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All required parameters verified',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Metabolic metrics recalculate automatically upon save.',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    color: Color(0xFF64748B),
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
  // PROFILE AVATAR
  // ============================================================
  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
                onBackgroundImageError: profileImageBytes != null
                    ? (error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => profileImageBytes = null);
                  });
                }
                    : null,
                child: profileImageBytes == null
                    ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF94A3B8))
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 36,
                height: 36,
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
                      color: const Color(0xFFE91E8C).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _pickImage(ImageSource.camera),
            child: _actionItem(Icons.camera_alt_outlined, 'Camera', const Color(0xFFE91E8C)),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => _pickImage(ImageSource.gallery),
            child: _actionItem(Icons.photo_library_outlined, 'Gallery', const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 14),
          InkWell(
            onTap: _removeImage,
            child: _actionItem(Icons.delete_outline_rounded, 'Remove', const Color(0xFFE11D48)),
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 11.5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM FIELDS
  // ============================================================
  Widget _buildFullNameField() {
    return _buildCustomField(
      label: 'Full Name',
      rightText: 'Valid',
      rightIcon: Icons.check_circle_rounded,
      rightColor: const Color(0xFF10B981),
      child: _buildEditableBox(
        controller: _fullNameController,
        icon: Icons.person_outline_rounded,
        suffix: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
      ),
    );
  }

  Widget _buildEmailField() {
    return _buildCustomField(
      label: 'Email Address',
      rightText: 'Primary ID',
      rightIcon: Icons.lock_outline_rounded,
      rightColor: const Color(0xFF64748B),
      infoText: 'Account identifier linked to database records.',
      infoIcon: Icons.info_outline_rounded,
      child: _buildEditableBox(
        controller: _emailController,
        icon: Icons.mail_outline_rounded,
        readOnly: true,
        suffix: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return _buildCustomField(
      label: 'Date of Birth',
      child: GestureDetector(
        onTap: _selectDate,
        child: AbsorbPointer(
          child: _buildEditableBox(
            controller: _dobController,
            icon: Icons.calendar_today_rounded,
            suffix: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF64748B), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    return _buildCustomField(
      label: 'Current Weight (kg)',
      rightText: 'BMR Baseline',
      rightColor: const Color(0xFF00ACC1),
      infoText: 'Updates your basal calorie calculation & macro quotas.',
      infoIcon: Icons.flash_on_rounded,
      infoIconColor: const Color(0xFF10B981),
      child: _buildEditableBox(
        controller: _weightController,
        icon: Icons.monitor_weight_outlined,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: Container(
          margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'kg',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeightField() {
    return _buildCustomField(
      label: 'Current Height (cm)',
      rightText: 'BMI Baseline',
      rightColor: const Color(0xFF00ACC1),
      child: _buildEditableBox(
        controller: _heightController,
        icon: Icons.straighten_rounded,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: Container(
          margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'cm',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalField() {
    return _buildCustomField(
      label: 'Primary Goal',
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: Color(0xFF475569), size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGoal,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                  items: goalOptions.map((goal) {
                    return DropdownMenuItem<String>(
                      value: goal,
                      child: Text(goal),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedGoal = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GENDER TOGGLE
  // ============================================================
  Widget _buildGenderSelection() {
    return _buildCustomField(
      label: 'Gender',
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _genderOption('Male'),
            _genderOption('Female'),
            _genderOption('Others'),
          ],
        ),
      ),
    );
  }

  Widget _genderOption(String title) {
    bool isSelected = selectedGender == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = title),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFFE91E8C).withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIELD HELPERS
  // ============================================================
  Widget _buildCustomField({
    required String label,
    required Widget child,
    String? rightText,
    IconData? rightIcon,
    Color? rightColor,
    String? infoText,
    IconData? infoIcon,
    Color? infoIconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                children: const [
                  TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE91E8C))),
                ],
              ),
            ),
            if (rightText != null)
              Row(
                children: [
                  if (rightIcon != null) ...[
                    Icon(rightIcon, size: 13, color: rightColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    rightText,
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: rightColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
        if (infoText != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(infoIcon, size: 13, color: infoIconColor ?? const Color(0xFF00ACC1)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  infoText,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEditableBox({
    required TextEditingController controller,
    required IconData icon,
    Widget? suffix,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: const Color(0xFF475569), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 13.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (suffix != null) ...[
            suffix,
            const SizedBox(width: 10),
          ]
        ],
      ),
    );
  }

  // ============================================================
  // BUTTONS
  // ============================================================
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E8C).withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isSaving ? null : _saveChanges,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
                const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscardButton() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Discard Edits',
          style: TextStyle(
            fontFamily: "Poppins",
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}