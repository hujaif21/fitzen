import 'dart:ui'; // Required for Glassmorphism ImageFilter
import 'package:flutter/material.dart';

class ActivityStreamScreen extends StatefulWidget {
  const ActivityStreamScreen({super.key});

  @override
  State<ActivityStreamScreen> createState() => _ActivityStreamScreenState();
}

class _ActivityStreamScreenState extends State<ActivityStreamScreen> {
  String selectedFilter = 'All (5)';
  bool isAllRead = false;
  List<String> dismissedIds = [];

  void _dismissNotification(String id) {
    setState(() {
      dismissedIds.add(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Notification dismissed',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      isAllRead = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'All notifications marked as read',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = isAllRead ? 0 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. FitZen Bioluminescent Aurora Mesh Background
          _buildAuroraBackground(),

          // 2. Main Page Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(unreadCount),
                        const SizedBox(height: 16),
                        _buildFilters(unreadCount),
                        const SizedBox(height: 18),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: [
                              _buildConsistencyCard(),
                              const SizedBox(height: 16),

                              // ==========================================
                              // UNREAD NOTIFICATION 1: DINNER REMINDER
                              // ==========================================
                              if (!dismissedIds.contains('dinner') &&
                                  (selectedFilter == 'All (5)' ||
                                      selectedFilter == 'Reminders' ||
                                      (selectedFilter.contains('Unread') && !isAllRead)))
                                _buildNotificationCard(
                                  id: 'dinner',
                                  isUnread: !isAllRead,
                                  icon: Icons.restaurant_rounded,
                                  gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                                  title: 'Dinner Log Reminder',
                                  time: '7:30 PM • Today',
                                  body:
                                  "Don't forget to log your dinner to keep your metabolic streak active and preserve BMR targets.",
                                  primaryActionText: 'Log Dinner',
                                  primaryActionIcon: Icons.add_rounded,
                                  secondaryActionText: 'Dismiss',
                                  onPrimaryTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Opening Meal Logger...'),
                                        backgroundColor: const Color(0xFFE91E8C),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  onSecondaryTap: () => _dismissNotification('dinner'),
                                ),

                              if (!dismissedIds.contains('dinner') &&
                                  (selectedFilter == 'All (5)' ||
                                      selectedFilter == 'Reminders' ||
                                      (selectedFilter.contains('Unread') && !isAllRead)))
                                const SizedBox(height: 14),

                              // ==========================================
                              // UNREAD NOTIFICATION 2: HYDRATION CHECK
                              // ==========================================
                              if (!dismissedIds.contains('water') &&
                                  (selectedFilter == 'All (5)' ||
                                      selectedFilter == 'Reminders' ||
                                      (selectedFilter.contains('Unread') && !isAllRead)))
                                _buildNotificationCard(
                                  id: 'water',
                                  isUnread: !isAllRead,
                                  icon: Icons.water_drop_rounded,
                                  gradient: const [Color(0xFF00ACC1), Color(0xFF008B87)],
                                  title: 'Hydration Checkpoint',
                                  time: '5:15 PM • Today',
                                  body:
                                  "You are 750 ml away from today's optimal fluid target. Log a quick intake now!",
                                  primaryActionText: '+ 250 ml Water',
                                  primaryActionIcon: Icons.local_drink_rounded,
                                  secondaryActionText: 'Dismiss',
                                  onPrimaryTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Added 250 ml to Hydration Log!'),
                                        backgroundColor: const Color(0xFF00ACC1),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  onSecondaryTap: () => _dismissNotification('water'),
                                ),

                              if (!dismissedIds.contains('water') &&
                                  (selectedFilter == 'All (5)' ||
                                      selectedFilter == 'Reminders' ||
                                      (selectedFilter.contains('Unread') && !isAllRead)))
                                const SizedBox(height: 14),

                              // ==========================================
                              // READ NOTIFICATION 1: NUTRITION TARGET
                              // ==========================================
                              if (!dismissedIds.contains('nutrition') &&
                                  (selectedFilter == 'All (5)' || selectedFilter == 'Reminders'))
                                _buildNotificationCard(
                                  id: 'nutrition',
                                  isUnread: false,
                                  icon: Icons.track_changes_rounded,
                                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                                  title: 'Nutrition Target Optimal',
                                  time: '2:00 PM • Today',
                                  body:
                                  "You've completed 80% of your daily nutrition macro targets with balanced protein density.",
                                  hasProgressBar: true,
                                  progressValue: 0.8,
                                ),

                              if (!dismissedIds.contains('nutrition') &&
                                  (selectedFilter == 'All (5)' || selectedFilter == 'Reminders'))
                                const SizedBox(height: 14),

                              // ==========================================
                              // READ NOTIFICATION 2: STREAK ACTIVE
                              // ==========================================
                              if (!dismissedIds.contains('streak') &&
                                  (selectedFilter == 'All (5)' || selectedFilter == 'Achievements'))
                                _buildNotificationCard(
                                  id: 'streak',
                                  isUnread: false,
                                  icon: Icons.local_fire_department_rounded,
                                  gradient: const [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                                  title: '7-Day Streak Active! 🔥',
                                  time: 'Yesterday',
                                  body:
                                  "Your 7-day tracking streak is going strong! Keep logging to reach your 10-day milestone.",
                                  badgeText: '7 Days Streak Achieved',
                                ),

                              if (!dismissedIds.contains('streak') &&
                                  (selectedFilter == 'All (5)' || selectedFilter == 'Achievements'))
                                const SizedBox(height: 14),

                              // ==========================================
                              // READ NOTIFICATION 3: ACHIEVEMENT
                              // ==========================================
                              if (!dismissedIds.contains('achievement') &&
                                  (selectedFilter == 'All (5)' || selectedFilter == 'Achievements'))
                                _buildNotificationCard(
                                  id: 'achievement',
                                  isUnread: false,
                                  icon: Icons.emoji_events_rounded,
                                  gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                                  title: 'New Achievement Unlocked',
                                  time: '2 days ago',
                                  body:
                                  "You unlocked 'Hydration Hero' by hitting your daily fluid goal 5 days in a row!",
                                  badgeText: 'Badge synced to profile',
                                ),

                              const SizedBox(height: 20),
                              _buildFooterNote(),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
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
  // UI GLASS & AURORA HELPERS
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
    Color? shadowColor,
  }) {
    final br = borderRadius ?? BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? const Color(0xFF0F172A).withValues(alpha: 0.04),
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
                'FitZen Activity',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Real-time notifications & insights',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 19),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Text(
            'Activity Stream',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 10),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$unreadCount New',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _markAllAsRead,
            child: Row(
              children: [
                Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: isAllRead ? const Color(0xFF94A3B8) : const Color(0xFFE91E8C),
                ),
                const SizedBox(width: 4),
                Text(
                  isAllRead ? 'All Read' : 'Mark all read',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isAllRead ? const Color(0xFF94A3B8) : const Color(0xFFE91E8C),
                    fontSize: 12,
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

  // ============================================================
  // FILTERS
  // ============================================================
  Widget _buildFilters(int unreadCount) {
    final filters = ['All (5)', 'Unread ($unreadCount)', 'Reminders', 'Achievements'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter ||
              (filter.startsWith('Unread') && selectedFilter.startsWith('Unread'));
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                  )
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFFE91E8C).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // CONSISTENCY BANNER
  // ============================================================
  Widget _buildConsistencyCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A3D).withValues(alpha: 0.18),
                  const Color(0xFFE91E8C).withValues(alpha: 0.18),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE91E8C), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistency Score: 94%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Daily habits remain on an optimal growth curve.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 18),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD BUILDER
  // ============================================================
  Widget _buildNotificationCard({
    required String id,
    required bool isUnread,
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String time,
    required String body,
    String? primaryActionText,
    IconData? primaryActionIcon,
    String? secondaryActionText,
    VoidCallback? onPrimaryTap,
    VoidCallback? onSecondaryTap,
    bool hasProgressBar = false,
    double progressValue = 0.0,
    String? badgeText,
  }) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Vessel with Gradient Accent
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradient[0].withValues(alpha: 0.16), gradient[1].withValues(alpha: 0.16)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gradient[1].withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: gradient[1], size: 22),
              ),
              const SizedBox(width: 14),

              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Time Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E8C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Body Text
                    Text(
                      body,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),

                    // Action Buttons Row
                    if (primaryActionText != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onPrimaryTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient[1].withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (primaryActionIcon != null) ...[
                                    Icon(primaryActionIcon, size: 15, color: Colors.white),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    primaryActionText,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (secondaryActionText != null) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: onSecondaryTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  secondaryActionText,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Progress Bar Feature
                    if (hasProgressBar) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(gradient[1]),
                        ),
                      ),
                    ],

                    // Achievement Badge Feature
                    if (badgeText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gradient[1].withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gradient[1].withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 13, color: gradient[1]),
                            const SizedBox(width: 5),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: gradient[1],
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER NOTE
  // ============================================================
  Widget _buildFooterNote() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.touch_app_outlined, size: 15, color: Color(0xFF94A3B8)),
          SizedBox(width: 6),
          Text(
            'Tap actions to log instantly or dismiss alerts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}