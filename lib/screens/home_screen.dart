// ============================================================
// home_screen.dart — Main dashboard with SOS button
// Contains bottom NavigationBar + IndexedStack for all 5 tabs
//   Real-time: live clock + periodic location status refresh
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/countdown_overlay.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import 'contacts_screen.dart';
import 'location_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showCountdown = false;
  String _locationStatus = 'Checking location…';
  int _countdownSeconds = 5;
  bool _isDemoMode = true;

  // ─── Real-time state ──────────────────────────────────────
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  Timer? _locationTimer;

  final SosService _sosService = SosService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadSettings();
    _refreshLocationStatus();

    // Live clock — ticks every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Auto-refresh location status every 30 seconds
    _locationTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshLocationStatus();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final seconds = await _storageService.getCountdownDuration();
    final demo = await _storageService.getDemoMode();
    if (mounted) {
      setState(() {
        _countdownSeconds = seconds;
        _isDemoMode = demo;
      });
    }
  }

  Future<void> _refreshLocationStatus() async {
    final status = await _locationService.getPermissionStatus();
    if (mounted) setState(() => _locationStatus = status);
  }

  // ─── SOS Flow ────────────────────────────────────────────────

  void _onSosHoldStart() {
    setState(() => _showCountdown = true);
  }

  void _onSosHoldCancel() {
    if (_showCountdown) setState(() => _showCountdown = false);
  }

  void _onSosActivated() {
    // SosButton long-press completed — countdown already showing
  }

  Future<void> _onCountdownComplete() async {
    setState(() => _showCountdown = false);
    _showSosProcessingDialog();
    final result = await _sosService.triggerSOS();
    if (mounted) {
      Navigator.of(context).pop(); // close processing dialog
      _showSosResultDialog(result.message, result.isDemoMode,
          result.locationResult?.hasLocation ?? false);
    }
  }

  void _onCountdownCancelled() {
    setState(() => _showCountdown = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS cancelled.'),
        backgroundColor: AppColors.textSecondary,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────

  void _showSosProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                    color: AppColors.sosRed, strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              const Text(
                'Activating SOS…',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Getting your location and\npreparing emergency alert.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSosResultDialog(
      String message, bool isDemoMode, bool locationOk) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.accentGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isDemoMode ? 'Demo Alert Sent' : 'SOS Alert Sent',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    AppStrings.demoModeNote,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              _statusStep('✅', 'SOS Activated', AppColors.accentGreen),
              _statusStep(
                locationOk ? '✅' : '⚠️',
                locationOk
                    ? 'Location Retrieved'
                    : 'Location Unavailable',
                locationOk
                    ? AppColors.accentGreen
                    : AppColors.accentOrange,
              ),
              _statusStep('✅', 'Alert Sent', AppColors.accentGreen),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            child: const Text('OK',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _statusStep(String emoji, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  // ─── Quick action grid button ────────────────────────────────

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.card,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Home tab content ────────────────────────────────────────

  // ─── Live clock widget ───────────────────────────────────
  Widget _buildLiveClock() {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_now);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sosRed.withOpacity(0.06),
            AppColors.accentBlue.withOpacity(0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.sosRed.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Real-time pulse indicator
          _LiveDot(),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Live clock
            _buildLiveClock(),

            const SizedBox(height: 12),

            // Demo mode banner
            if (_isDemoMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.demoModeNote,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Location status chip (tap to go to location tab)
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _locationStatus,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // SOS Button
            SizedBox(
              height: 240,
              child: Center(
                child: SosButton(
                  onActivated: _onSosActivated,
                  onHoldStart: _onSosHoldStart,
                  onHoldCancel: _onSosHoldCancel,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Label
            const Text(
              AppStrings.sosButtonLabel,
              style: AppTextStyles.sosLabel,
            ),

            const SizedBox(height: 36),

            // Quick action 2×2 grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _quickAction(
                  icon: Icons.contacts_rounded,
                  label: 'Emergency\nContacts',
                  color: AppColors.accentBlue,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _quickAction(
                  icon: Icons.location_on_rounded,
                  label: 'My\nLocation',
                  color: AppColors.accentGreen,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _quickAction(
                  icon: Icons.history_rounded,
                  label: 'SOS\nHistory',
                  color: AppColors.sosRed,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _quickAction(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: AppColors.accentOrange,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // All 5 tab screens
    final List<Widget> screens = [
      _buildHomePage(),
      const ContactsScreen(),
      const LocationScreen(),
      const HistoryScreen(),
      SettingsScreen(onSettingsChanged: _loadSettings),
    ];

    final List<String> titles = [
      'Emergency Assistance',
      'Emergency Contacts',
      'My Location',
      'SOS History',
      'Settings',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentIndex == 0) ...[
              const Icon(Icons.health_and_safety_rounded,
                  color: AppColors.sosRed, size: 26),
              const SizedBox(width: 8),
            ],
            Text(titles[_currentIndex], style: AppTextStyles.screenTitle),
          ],
        ),
        centerTitle: false,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary),
              onPressed: () {
                _refreshLocationStatus();
                _loadSettings();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Stack(
        children: [
          // UseIndexedStack so tabs keep their state when switching
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // Countdown overlay on top of everything
          if (_showCountdown)
            CountdownOverlay(
              countdownSeconds: _countdownSeconds,
              onComplete: _onCountdownComplete,
              onCancelled: _onCountdownCancelled,
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (_showCountdown) return;
          setState(() => _currentIndex = i);
        },
        backgroundColor: AppColors.cardBackground,
        indicatorColor: AppColors.sosRed.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home_rounded, color: AppColors.sosRed),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon:
                Icon(Icons.contacts_rounded, color: AppColors.sosRed),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon:
                Icon(Icons.location_on_rounded, color: AppColors.sosRed),
            label: 'Location',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon:
                Icon(Icons.history_rounded, color: AppColors.sosRed),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppColors.sosRed),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing live dot ────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'LIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.accentGreen,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
