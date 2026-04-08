import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  static const int _workMinutes = 25;
  static const int _breakMinutes = 5;

  int _totalSeconds = _workMinutes * 60;
  int _remainingSeconds = _workMinutes * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _pomodoroCount = 0;
  int _targetPomodoros = 4;
  Timer? _timer;

  late AnimationController _bgController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _presets = [
    {'label': '25 min', 'minutes': 25, 'break': 5},
    {'label': '45 min', 'minutes': 45, 'break': 10},
    {'label': '60 min', 'minutes': 60, 'break': 15},
  ];
  int _selectedPreset = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    final minutes = _presets[_selectedPreset]['minutes'] as int;
    setState(() {
      _isRunning = false;
      _totalSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      _isBreak = false;
    });
  }

  void _skipToBreak() {
    _timer?.cancel();
    _onTimerComplete();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();

    if (!_isBreak) {
      // Work session done
      final session = FocusSession(
        id: const Uuid().v4(),
        userId: FirebaseAuth.instance.currentUser!.uid,
        durationMinutes: _presets[_selectedPreset]['minutes'] as int,
        isCompleted: true,
      );
      context.read<AppProvider>().saveFocusSession(session);

      setState(() {
        _pomodoroCount++;
        _isBreak = true;
        final breakMins = _presets[_selectedPreset]['break'] as int;
        _totalSeconds = breakMins * 60;
        _remainingSeconds = breakMins * 60;
        _isRunning = false;
      });
      _showSessionComplete();
    } else {
      setState(() {
        _isBreak = false;
        final mins = _presets[_selectedPreset]['minutes'] as int;
        _totalSeconds = mins * 60;
        _remainingSeconds = mins * 60;
        _isRunning = false;
      });
    }
  }

  void _showSessionComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              'Session complete! Take a break.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _remainingSeconds / (_totalSeconds == 0 ? 1 : _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) {
          return Stack(
            children: [
              // Ambient gradient background
              Positioned(
                top: -size.height * 0.1,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (_isBreak ? AppColors.secondary : AppColors.primary)
                            .withOpacity(0.12 + _bgController.value * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -size.height * 0.1,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary
                            .withOpacity(0.08 + _bgController.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // App bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: AppColors.darkTextPrimary, size: 20),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _isBreak ? '☕ Break Time' : '⚡ Focus Mode',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preset selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _presets.asMap().entries.map((entry) {
                        final i = entry.key;
                        final preset = entry.value;
                        final selected = _selectedPreset == i;
                        return GestureDetector(
                          onTap: _isRunning
                              ? null
                              : () {
                                  setState(() {
                                    _selectedPreset = i;
                                    final mins = preset['minutes'] as int;
                                    _totalSeconds = mins * 60;
                                    _remainingSeconds = mins * 60;
                                    _isBreak = false;
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.darkBorder,
                              ),
                            ),
                            child: Text(
                              preset['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // Timer ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, child) {
                        final pulse = _isRunning
                            ? 1.0 + _pulseController.value * 0.03
                            : 1.0;
                        return Transform.scale(
                          scale: pulse,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              painter: _FocusRingPainter(
                                progress: _progress,
                                isBreak: _isBreak,
                              ),
                              child: const SizedBox(width: 260, height: 260),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkTextPrimary,
                                    letterSpacing: -2,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  _isBreak ? 'break' : 'focus',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isBreak
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 32),

                    // Pomodoro dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_targetPomodoros, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: i < _pomodoroCount ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i < _pomodoroCount
                                ? AppColors.primary
                                : AppColors.darkBorder,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Pomodoro $_pomodoroCount of $_targetPomodoros',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),

                    const Spacer(),

                    // Controls
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Reset
                          _ControlBtn(
                            icon: Icons.replay_rounded,
                            onTap: _resetTimer,
                            size: 48,
                          ),
                          // Play/Pause (main)
                          _ControlBtn(
                            icon: _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onTap: _isRunning ? _pauseTimer : _startTimer,
                            size: 68,
                            isMain: true,
                            color: _isBreak
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                          // Skip
                          _ControlBtn(
                            icon: Icons.skip_next_rounded,
                            onTap: _skipToBreak,
                            size: 48,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool isMain;
  final Color color;

  const _ControlBtn({
    required this.icon,
    required this.onTap,
    required this.size,
    this.isMain = false,
    this.color = AppColors.primary,
  });

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isMain ? widget.color : AppColors.darkSurfaceElevated,
            shape: BoxShape.circle,
            boxShadow: widget.isMain
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: widget.isMain ? Colors.white : AppColors.darkTextSecondary,
            size: widget.isMain ? 32 : 22,
          ),
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  final bool isBreak;

  const _FocusRingPainter({required this.progress, required this.isBreak});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Glow
    if (progress < 1.0) {
      final glowPaint = Paint()
        ..shader = (isBreak
                ? const LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight])
                : const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]))
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    // Progress arc
    final progressPaint = Paint()
      ..shader = (isBreak
              ? const LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondaryLight])
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight]))
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.progress != progress || old.isBreak != isBreak;
}
