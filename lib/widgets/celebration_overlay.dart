import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';

/// Full-screen celebration overlay with confetti animation
class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final int? xpEarned;
  final VoidCallback? onDismiss;

  const CelebrationOverlay({
    super.key,
    this.title = 'Congratulations!',
    this.subtitle = 'You completed your first ritual!',
    this.xpEarned,
    this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _confettiController.play();
    _animationController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
              child: Stack(
                children: [
                  // Confetti from top center
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 50,
                      gravity: 0.1,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFF00D2FF),
                        Color(0xFFFF6B6B),
                        Color(0xFFFFD93D),
                        Color(0xFF6BCB77),
                        Color(0xFFAD8BFE),
                      ],
                    ),
                  ),

                  // Content
                  Center(
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.surfaceColor,
                                AppTheme.surfaceColor.withValues(alpha: 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Trophy emoji with glow
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFD93D).withValues(alpha: 0.2),
                                ),
                                child: const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 64),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Title
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // XP earned
                              if (widget.xpEarned != null) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    '+${widget.xpEarned} XP',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              Text(
                                'Tap anywhere to continue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Helper function to show celebration overlay
void showCelebration(
  BuildContext context, {
  String title = 'Congratulations!',
  String subtitle = 'You completed your first ritual!',
  int? xpEarned,
}) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => CelebrationOverlay(
      title: title,
      subtitle: subtitle,
      xpEarned: xpEarned,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}
