import 'dart:ui';
import 'package:flutter/material.dart';
import 'core_settings.dart';
import 'profile.dart';

class FitzenSettingsScreen extends StatefulWidget {
  const FitzenSettingsScreen({super.key});

  @override
  State<FitzenSettingsScreen> createState() => _FitzenSettingsScreenState();
}

class _FitzenSettingsScreenState extends State<FitzenSettingsScreen> {
  // Units & Measurements State
  String _weightUnit = 'kg';
  String _waterVolumeUnit = 'ml';

  // Data & Integrations State
  bool _syncGoogleFit = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return FitzenScreen(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Executive Status Card
              _buildExecutiveStatusCard(context),
              const SizedBox(height: 20),

              // Section 1: App Preferences
              _buildSectionHeader(context, tr('APP PREFERENCES')),
              const SizedBox(height: 10),
              _buildCardWrapper(
                context: context,
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: tr('Dark Theme'),
                    subtitle: tr('Enable dark mode interface'),
                    value: themeNotifier.value == ThemeMode.dark,
                    onChanged: (val) {
                      setState(() {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      });
                    },
                  ),
                  _buildCardDivider(context),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.language_rounded,
                    title: tr('Language'),
                    trailingText: languageNotifier.value,
                    onTap: () {
                      _showLanguagePicker(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 2: Units & Measurements
              _buildSectionHeader(context, tr('UNITS & MEASUREMENTS')),
              const SizedBox(height: 10),
              _buildCardWrapper(
                context: context,
                children: [
                  _buildSegmentedTile(
                    context: context,
                    icon: Icons.scale_rounded,
                    title: tr('Weight Unit'),
                    currentSelection: _weightUnit,
                    options: const ['kg', 'lbs'],
                    onSelected: (val) {
                      setState(() {
                        _weightUnit = val;
                      });
                    },
                  ),
                  _buildCardDivider(context),
                  _buildSegmentedTile(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    title: tr('Water Volume'),
                    currentSelection: _waterVolumeUnit,
                    options: const ['ml', 'fl oz'],
                    onSelected: (val) {
                      setState(() {
                        _waterVolumeUnit = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 3: Data & Integrations
              _buildSectionHeader(context, tr('DATA & INTEGRATIONS')),
              const SizedBox(height: 10),
              _buildCardWrapper(
                context: context,
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.sync_rounded,
                    title: tr('Sync with Google Fit'),
                    subtitle: tr('Bi-directional daily metrics sync'),
                    value: _syncGoogleFit,
                    onChanged: (val) {
                      setState(() {
                        _syncGoogleFit = val;
                      });
                    },
                  ),
                  _buildCardDivider(context),
                  _buildActionTile(
                    context: context,
                    icon: Icons.file_download_outlined,
                    title: tr('Export My Data'),
                    subtitle: tr('Download complete nutrition & metrics archive'),
                    trailingIcon: Icons.download_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('Preparing data export in JSON/CSV...'),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFFE91E8C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 4: Support & About
              _buildSectionHeader(context, tr('SUPPORT & ABOUT')),
              const SizedBox(height: 10),
              _buildCardWrapper(
                context: context,
                children: [
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: tr('Help Center & FAQ'),
                    onTap: () {},
                  ),
                  _buildCardDivider(context),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: tr('Privacy Policy'),
                    onTap: () {},
                  ),
                  _buildCardDivider(context),
                  _buildNavigationTile(
                    context: context,
                    icon: Icons.description_outlined,
                    title: tr('Terms of Service'),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      'FitZen Executive Systems',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'App Version 2.4.0 • Enterprise Edition',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.card(context).withOpacity(0.85),
          border: Border(
            bottom: BorderSide(
              color: AppColors.border(context),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border(context), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E8C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FitZen',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      tr('Settings'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXECUTIVE BANNER CARD
  // ============================================================
  Widget _buildExecutiveStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: AppColors.isDark(context)
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border.all(color: AppColors.border(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A3D).withOpacity(0.18),
                  const Color(0xFFE91E8C).withOpacity(0.18),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE91E8C), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences & Engine',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customized for executive health telemetry',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Text(
              'Synced',
              style: TextStyle(
                fontFamily: 'Poppins',
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

  // ============================================================
  // CARD & SECTION HELPERS
  // ============================================================
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textSecondary(context),
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required BuildContext context, required List<Widget> children}) {
    final br = BorderRadius.circular(22.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardGlass(context),
              borderRadius: br,
              border: Border.all(color: AppColors.border(context), width: 1.2),
            ),
            child: Column(
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 0,
      color: AppColors.border(context),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.iconBg(context),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(icon, size: 19, color: AppColors.primaryAccent),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.textSecondary(context),
        ),
      )
          : null,
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primaryAccent,
        activeTrackColor: AppColors.primaryAccent.withOpacity(0.35),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.isDark(context) ? const Color(0xFF334155) : Colors.grey.shade400,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.iconBg(context),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(icon, size: 19, color: AppColors.primaryAccent),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailingText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary(context),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.iconBg(context),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(icon, size: 19, color: AppColors.primaryAccent),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.textSecondary(context),
        ),
      )
          : null,
      trailing: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          trailingIcon,
          size: 16,
          color: AppColors.primaryAccent,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSegmentedTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String currentSelection,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.iconBg(context),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(icon, size: 19, color: AppColors.primaryAccent),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context),
        ),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: AppColors.isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border(context), width: 1.0),
        ),
        padding: const EdgeInsets.all(3.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final bool isSelected = opt == currentSelection;
            return GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                  )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.0),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFFE91E8C).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  tr(opt),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE PICKER MODAL
  // ============================================================
  void _showLanguagePicker(BuildContext context) {
    final languages = ['English', 'Spanish', 'French'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardGlass(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.border(context), width: 1.2),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('Select Language'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppColors.border(context)),
                    const SizedBox(height: 8),
                    ...languages.map((lang) {
                      final isSelected = lang == languageNotifier.value;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        title: Text(
                          lang,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryAccent : AppColors.textPrimary(context),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent)
                            : null,
                        onTap: () {
                          setState(() {
                            languageNotifier.value = lang;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}