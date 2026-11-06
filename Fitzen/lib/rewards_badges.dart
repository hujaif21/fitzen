import 'package:flutter/material.dart';

class RewardsBadgesScreen extends StatelessWidget {
  const RewardsBadgesScreen({super.key});

  static const Color _bgColor = Color(0xFFFAFAFA);
  static const Color _primaryAccent = Color(0xFFC91D2B);
  static const Color _lightPinkBg = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTierCard(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('UNLOCKED BADGES', '4'),
                    const SizedBox(height: 12),
                    _buildBadgesGrid(unlocked: true),
                    const SizedBox(height: 28),
                    _buildSectionHeader('LOCKED MILESTONES', '6'),
                    const SizedBox(height: 12),
                    _buildBadgesGrid(unlocked: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR (Consistent Fitzen Style)
  // ============================================================
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.arrow_back, size: 24, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightPinkBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: _primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitzen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Georgia',
                ),
              ),
              Text(
                'Rewards',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _primaryAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIER & XP CARD
  // ============================================================
  Widget _buildTierCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0EBE9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 40,
                color: Color(0xFF78909C), // Silver color
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Silver Tier',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Top 15% of Fitzen users this month',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '2,450 XP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryAccent,
                  ),
                ),
                Text(
                  '3,000 XP for Gold',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 2450 / 3000,
                minHeight: 8,
                backgroundColor: Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation<Color>(_primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADERS
  // ============================================================
  Widget _buildSectionHeader(String title, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.9,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGES GRID
  // ============================================================
  Widget _buildBadgesGrid({required bool unlocked}) {
    final unlockedBadges = [
      {'title': 'Hydration Hero', 'desc': '5 days water goal', 'icon': Icons.water_drop, 'color': const Color(0xFF008B87), 'bg': const Color(0xFFE0F7FA)},
      {'title': '7-Day Streak', 'desc': 'Logged 7 days', 'icon': Icons.local_fire_department, 'color': const Color(0xFFFF6D00), 'bg': const Color(0xFFFFF3E0)},
      {'title': 'Early Bird', 'desc': 'Breakfast logged', 'icon': Icons.wb_sunny, 'color': const Color(0xFFFBC02D), 'bg': const Color(0xFFFFF9C4)},
      {'title': 'First Step', 'desc': 'Profile completed', 'icon': Icons.check_circle, 'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9)},
    ];

    final lockedBadges = [
      {'title': 'Nutrition Master', 'desc': 'Perfect macros', 'icon': Icons.pie_chart},
      {'title': '30-Day Streak', 'desc': 'Logged 30 days', 'icon': Icons.calendar_month},
      {'title': 'Goal Crusher', 'desc': 'Hit primary goal', 'icon': Icons.flag},
      {'title': 'Night Owl', 'desc': 'Late workout', 'icon': Icons.nightlight_round},
    ];

    final data = unlocked ? unlockedBadges : lockedBadges;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildBadgeItem(
          title: item['title'] as String,
          desc: item['desc'] as String,
          icon: item['icon'] as IconData,
          isUnlocked: unlocked,
          iconColor: item['color'] as Color?,
          iconBg: item['bg'] as Color?,
        );
      },
    );
  }

  Widget _buildBadgeItem({
    required String title,
    required String desc,
    required IconData icon,
    required bool isUnlocked,
    Color? iconColor,
    Color? iconBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EBE9)),
        boxShadow: isUnlocked
            ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnlocked ? iconBg : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isUnlocked ? iconColor : const Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? const Color(0xFF222222) : const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isUnlocked ? const Color(0xFF666666) : const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }
}