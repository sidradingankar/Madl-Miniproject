// ============================================================
// countdown_overlay.dart — Full-screen SOS countdown overlay
// ============================================================

import 'dart:async';
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Warning icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 24),

                // Headline
                const Text(
                  'SOS ACTIVATING',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Emergency alert will be sent to\nyour emergency contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
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
                    style: AppTextStyles.countdownNumber,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'seconds remaining',
                  style: TextStyle(
                    fontSize: 16,
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

                const SizedBox(height: 48),

                // CANCEL button — large and accessible
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sosRed,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CANCEL SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
