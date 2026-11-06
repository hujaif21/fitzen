import 'dart:async';
import 'dart:ui'; // Required for ImageFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'core_settings.dart';
import 'network/api_service.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Set<int> _completedSessions = {};

  final Map<int, List<Map<String, String>>> _routines = {
    0: [
      {
        'title': 'Morning Full Body Stretch',
        'duration': '10 mins',
        'calories': '45 kcal',
        'desc': 'Gentle mobility flow to wake up joints and muscles. Perfect for starting your day with flexibility and deep breathing to increase oxygen flow.',
        'videoPath': 'assets/videos/morning_1.mp4',
      },
      {
        'title': 'Core Activation & Planks',
        'duration': '8 mins',
        'calories': '60 kcal',
        'desc': 'Engage your transverse abdominis and prep for the day. This builds a strong foundational core to protect your lower back.',
        'videoPath': 'assets/videos/morning_2.mp4',
      },
    ],
    1: [
      {
        'title': 'High-Intensity Cardio Blast',
        'duration': '15 mins',
        'calories': '150 kcal',
        'desc': 'Jumping jacks, high knees, and bodyweight squats to maximize your heart rate and trigger the afterburn effect.',
        'videoPath': 'assets/videos/evening_1.mp4',
      },
      {
        'title': 'Upper Body Strength',
        'duration': '12 mins',
        'calories': '110 kcal',
        'desc': 'Build chest, shoulders, and triceps strength using advanced bodyweight techniques and slow eccentric movements.',
        'videoPath': 'assets/videos/evening_2.mp4',
      },
    ],
    2: [
      {
        'title': 'Wind Down Yoga',
        'duration': '10 mins',
        'calories': '30 kcal',
        'desc': 'Relieve spine tension and lower heart rate before bed. Activates the parasympathetic nervous system for deep sleep.',
        'videoPath': 'assets/videos/night_1.mp4',
      },
      {
        'title': 'Lower Back Relief',
        'duration': '8 mins',
        'calories': '25 kcal',
        'desc': 'Release tight postural muscles from the day. Essential for those who spend hours sitting at a desk.',
        'videoPath': 'assets/videos/night_2.mp4',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    return 'exercise_${now.day}_${now.month}_${now.year}';
  }

  Future<void> _loadSavedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList(_todayKey());
    if (savedList != null && mounted) {
      setState(() {
        _completedSessions.clear();
        for (var item in savedList) {
          _completedSessions.add(int.parse(item));
        }
      });
    }
  }

  Future<void> _saveSavedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> listToSave = _completedSessions.map((e) => e.toString()).toList();
    await prefs.setStringList(_todayKey(), listToSave);
  }

  Future<void> _toggleSessionCompletion(int sessionIndex, String sessionName) async {
    final bool willBeCompleted = !_completedSessions.contains(sessionIndex);

    setState(() {
      if (willBeCompleted) {
        _completedSessions.add(sessionIndex);
      } else {
        _completedSessions.remove(sessionIndex);
      }
    });

    await _saveSavedExercises();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';

      if (email.isNotEmpty) {
        await ApiService.logExercise(
          email: email,
          sessionType: sessionName,
          isCompleted: willBeCompleted,
        );
      }
    } catch (e) {
      debugPrint('Exercise Sync Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        final bool isGoalMet = _completedSessions.length >= 2;
        final isDark = AppColors.isDark(context);

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Stack(
            children: [
              _buildAuroraBackground(context),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: _buildGlassCard(
                        context: context,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shadowColor: isGoalMet
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFFFF8A3D).withOpacity(0.12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: isGoalMet
                                    ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                                    : const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGoalMet ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isGoalMet ? 'Daily Goal Met (2+ Done)' : 'Goal: Complete 2/3 Sessions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isGoalMet
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                          : AppColors.textPrimary(context),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Completed: ${_completedSessions.length}/3 sessions today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary(context),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGlassCard(
                        context: context,
                        padding: const EdgeInsets.all(6),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E8C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary(context),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Poppins'),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, fontFamily: 'Poppins'),
                          tabs: [
                            _buildTab('🌅 Morning', 0),
                            _buildTab('🌇 Evening', 1),
                            _buildTab('🌙 Night', 2),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRoutineList(context, 0, 'Morning'),
                          _buildRoutineList(context, 1, 'Evening'),
                          _buildRoutineList(context, 2, 'Night'),
                        ],
                      ),
                    ),
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

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Color? shadowColor,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04)),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
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

  Widget _buildHeader(BuildContext context) {
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
              decoration: BoxDecoration(
                color: AppColors.card(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context), width: 1.2),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: AppColors.textPrimary(context)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E8C).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Daily Routines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(String text, int index) {
    final bool isCompleted = _completedSessions.contains(index);
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text),
            if (isCompleted) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle_rounded, size: 12),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList(BuildContext context, int sessionIndex, String sessionName) {
    final exercises = _routines[sessionIndex] ?? [];
    final bool isCompleted = _completedSessions.contains(sessionIndex);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$sessionName Routine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                fontFamily: 'Poppins',
                letterSpacing: -0.3,
              ),
            ),
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: isCompleted ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]) : null,
                color: isCompleted ? null : AppColors.cardGlass(context),
                borderRadius: BorderRadius.circular(12),
                border: isCompleted ? null : Border.all(color: AppColors.border(context), width: 1.2),
                boxShadow: isCompleted
                    ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _toggleSessionCompletion(sessionIndex, sessionName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: isCompleted ? Colors.white : AppColors.textPrimary(context),
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                ),
                label: Text(
                  isCompleted ? 'Completed' : 'Mark Done',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...exercises.map((ex) {
          return RoutineVideoCard(
            key: ValueKey(ex['title']),
            videoPath: ex['videoPath'] ?? '',
            title: ex['title'] ?? '',
            desc: ex['desc'] ?? '',
            duration: ex['duration'] ?? '',
            calories: ex['calories'] ?? '',
          );
        }),
      ],
    );
  }
}

// ============================================================================
// ROUTINE VIDEO CARD
// ============================================================================
class RoutineVideoCard extends StatefulWidget {
  final String videoPath;
  final String title;
  final String desc;
  final String duration;
  final String calories;

  const RoutineVideoCard({
    super.key,
    required this.videoPath,
    required this.title,
    required this.desc,
    required this.duration,
    required this.calories,
  });

  @override
  State<RoutineVideoCard> createState() => _RoutineVideoCardState();
}

class _RoutineVideoCardState extends State<RoutineVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.videoPath);
      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Video error initializing ${widget.videoPath}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final double cardAspectRatio = (_controller != null && _controller!.value.isInitialized && _controller!.value.aspectRatio > 0)
        ? _controller!.value.aspectRatio
        : (9 / 16);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardGlass(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: cardAspectRatio,
              child: Container(
                color: Colors.black,
                child: widget.videoPath.isNotEmpty && _isInitialized && _controller != null && !_hasError
                    ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoDetailScreen(
                          videoPath: widget.videoPath,
                          title: widget.title,
                          desc: widget.desc,
                          duration: widget.duration,
                          calories: widget.calories,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                )
                    : GestureDetector(
                  onTap: _hasError ? _initVideo : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(
                          _hasError ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                          size: 42,
                          color: const Color(0xFFE91E8C),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        child: Text(
                          _hasError
                              ? 'Tap to Retry Loading'
                              : (widget.videoPath.isNotEmpty ? 'Loading preview...' : 'No Video Available'),
                          style: TextStyle(
                            color: _hasError ? const Color(0xFFFF8A3D) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _badge(widget.duration, Icons.timer_rounded, const [Color(0xFFFFB259), Color(0xFFFF8A3D)]),
                    const SizedBox(width: 8),
                    _badge(widget.calories, Icons.local_fire_department_rounded, const [Color(0xFFFF5376), Color(0xFFE91E8C)]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: gradient[1].withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: gradient[1]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: gradient[1], fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ============================================================================
// VERTICAL VIDEO DETAIL SCREEN
// ============================================================================
class VideoDetailScreen extends StatefulWidget {
  final String videoPath;
  final String title;
  final String desc;
  final String duration;
  final String calories;

  const VideoDetailScreen({
    super.key,
    required this.videoPath,
    required this.title,
    required this.desc,
    required this.duration,
    required this.calories,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;

  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _hideTimer;

  bool _showRewindIcon = false;
  bool _showForwardIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _startHideTimer();
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    });
  }

  void _seekForward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition + const Duration(seconds: 10);
    _controller.seekTo(targetPosition);

    setState(() => _showForwardIcon = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showForwardIcon = false);
    });
    _startHideTimer();
  }

  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition - const Duration(seconds: 10);
    _controller.seekTo(targetPosition);

    setState(() => _showRewindIcon = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showRewindIcon = false);
    });
    _startHideTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final double playerAspectRatio = (_controller.value.isInitialized && _controller.value.aspectRatio > 0)
        ? _controller.value.aspectRatio
        : (9 / 16);

    Widget videoContent = Container(
      color: Colors.black,
      width: double.infinity,
      child: Stack(
        children: [
          if (_controller.value.isInitialized)
            Center(
              child: VideoPlayer(_controller),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C))),

          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTap: _seekBackward,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTap: _seekForward,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
              ],
            ),
          ),

          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              if (_isFullScreen) {
                                _toggleFullScreen();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          _startHideTimer();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_controller.value.position),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: const Color(0xFFE91E8C),
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                                thumbColor: const Color(0xFFFF8A3D),
                              ),
                              child: Slider(
                                value: _controller.value.position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: _controller.value.duration.inMilliseconds.toDouble(),
                                onChanged: (value) {
                                  _controller.seekTo(Duration(milliseconds: value.toInt()));
                                  _startHideTimer();
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_controller.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _toggleFullScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showRewindIcon)
            const Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 4),
                    Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          if (_showForwardIcon)
            const Positioned(
              right: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 4),
                    Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isFullScreen) _toggleFullScreen();
      },
      child: Scaffold(
        backgroundColor: _isFullScreen ? Colors.black : AppColors.background(context),
        body: Column(
          children: [
            if (_isFullScreen)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: playerAspectRatio,
                    child: videoContent,
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: playerAspectRatio,
                child: videoContent,
              ),

            if (!_isFullScreen)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          fontFamily: 'Poppins',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildGlassTag(widget.duration, Icons.timer_rounded, const [Color(0xFFFFB259), Color(0xFFFF8A3D)]),
                          const SizedBox(width: 12),
                          _buildGlassTag(widget.calories, Icons.local_fire_department_rounded, const [Color(0xFFFF5376), Color(0xFFE91E8C)]),
                          const SizedBox(width: 12),
                          _buildGlassTag('Video', Icons.play_circle_filled_rounded, const [Color(0xFF26C6DA), Color(0xFF008B87)]),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.desc,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary(context),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTag(String text, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gradient[1].withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradient[1].withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: gradient[1]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: gradient[1],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}