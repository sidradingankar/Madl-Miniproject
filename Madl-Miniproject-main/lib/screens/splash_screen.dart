// ============================================================
// splash_screen.dart — Animated app splash/intro screen
//   Responsive: adapts to all screen sizes
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    // Start animation, then navigate to home
    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Responsive sizing
    final logoSize = math.min(screenWidth * 0.3, 120.0);
    final iconSize = logoSize * 0.57;
    final titleSize = math.min(screenWidth * 0.085, 34.0);
    final subtitleSize = math.min(screenWidth * 0.07, 28.0);
    final taglineSize = math.min(screenWidth * 0.035, 14.0);

    return Scaffold(
      backgroundColor: AppColors.sosRed,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon / logo
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 3),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 18 : 28),

                  // App name
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Text(
                      'Emergency',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Text(
                      'Assistance',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 16),

                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Text(
                      'Your Safety, Our Priority',
                      style: TextStyle(
                        fontSize: taglineSize,
                        color: Colors.white60,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 50 : 80),

                  // Loading indicator
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2.5,
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
