// ============================================================
// sos_button.dart — Animated hold-to-activate SOS button
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class SosButton extends StatefulWidget {
  /// Called when the long-press hold duration completes (triggers SOS)
  final VoidCallback onActivated;

  /// Called when the user starts holding (show countdown)
  final VoidCallback onHoldStart;

  /// Called when the user releases before time is up (cancel)
  final VoidCallback onHoldCancel;

  const SosButton({
    super.key,
    required this.onActivated,
    required this.onHoldStart,
    required this.onHoldCancel,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with TickerProviderStateMixin {
  // Outer pulse animation (slow breathing ring)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Inner press scale animation
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Pulse ring: continuously expands and fades
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale: shrinks slightly when pressed
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPressStart(details) {
    setState(() => _isPressed = true);
    _scaleController.reverse(); // shrink button
    HapticFeedback.heavyImpact();
    widget.onHoldStart();
  }

  void _onPressEnd(details) {
    setState(() => _isPressed = false);
    _scaleController.forward(); // restore button
    widget.onHoldCancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onPressStart,
      onLongPressEnd: _onPressEnd,
      onLongPressCancel: () {
        setState(() => _isPressed = false);
        _scaleController.forward();
        widget.onHoldCancel();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse ring
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPressed
                        ? AppColors.sosRed.withOpacity(0.15)
                        : AppColors.sosRedGlow.withOpacity(0.25),
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressed
                      ? AppColors.sosRed.withOpacity(0.25)
                      : AppColors.sosRedGlow.withOpacity(0.35),
                ),
              ),
              // Main button — scales down when pressed
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: _isPressed
                          ? [AppColors.sosRedDark, AppColors.sosRed]
                          : [AppColors.sosRedLight, AppColors.sosRed],
                      center: Alignment.topLeft,
                      radius: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosRed.withOpacity(0.5),
                        blurRadius: _isPressed ? 20 : 35,
                        spreadRadius: _isPressed ? 2 : 8,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sos_rounded,
                        color: AppColors.textWhite,
                        size: 56,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textWhite,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
