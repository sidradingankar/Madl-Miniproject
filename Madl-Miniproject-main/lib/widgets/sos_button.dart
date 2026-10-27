// ============================================================
// sos_button.dart — Animated hold-to-activate SOS button
//   Responsive: sizes adapt to screen width
// ============================================================

import 'dart:math' as math;
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
    // Responsive sizing: use the smaller of width/height to compute button size
    final screenWidth = MediaQuery.of(context).size.width;
    // Cap the button size at reasonable bounds
    final baseSize = math.min(screenWidth * 0.42, 210.0);
    final outerSize = baseSize;
    final middleSize = baseSize * 0.88;  // ~185 on 210 base
    final innerSize = baseSize * 0.74;   // ~155 on 210 base
    final iconSize = baseSize * 0.27;    // ~56 on 210 base
    final labelSize = baseSize * 0.105;  // ~22 on 210 base

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
                  width: outerSize,
                  height: outerSize,
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
                width: middleSize,
                height: middleSize,
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
                  width: innerSize,
                  height: innerSize,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sos_rounded,
                        color: AppColors.textWhite,
                        size: iconSize,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: labelSize,
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
