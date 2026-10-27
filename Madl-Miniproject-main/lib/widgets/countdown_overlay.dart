// ============================================================
// countdown_overlay.dart — Full-screen SOS countdown overlay
//   Responsive: adapts to all screen sizes
// ============================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class CountdownOverlay extends StatefulWidget {
  final int countdownSeconds;
  final VoidCallback onComplete;   // SOS goes through
  final VoidCallback onCancelled;  // User pressed CANCEL

  const CountdownOverlay({
    super.key,
    required this.countdownSeconds,
    required this.onComplete,
    required this.onCancelled,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;

  // Number scale animation — each tick bounces
  late AnimationController _numberAnimController;
  late Animation<double> _numberScaleAnim;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;

    _numberAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _numberScaleAnim = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _numberAnimController, curve: Curves.elasticOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    // Animate first number
    _numberAnimController.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      HapticFeedback.mediumImpact(); // tactile feedback each second
      setState(() {
        _remaining--;
      });
      _numberAnimController.forward(from: 0);

      if (_remaining <= 0) {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    widget.onCancelled();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _numberAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    // Responsive countdown number size
    final countdownFontSize = math.min(screenHeight * 0.12, 96.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        // Full-screen dark red overlay
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.sosRedDark.withOpacity(0.96),
              AppColors.sosRed.withOpacity(0.94),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 30 : 60),

                // Warning icon
                Container(
                  width: isSmallScreen ? 60 : 80,
                  height: isSmallScreen ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 36 : 48,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Headline
                Text(
                  'SOS ACTIVATING',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 4 : 8),

                Text(
                  'Emergency alert will be sent to\nyour emergency contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Countdown number with animation
                ScaleTransition(
                  scale: _numberScaleAnim,
                  child: Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: countdownFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 6 : 12),

                Text(
                  'seconds remaining',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),

                const Spacer(),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:
                        _remaining / widget.countdownSeconds,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 48),

                // CANCEL button — large and accessible
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sosRed,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CANCEL SOS',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
