// ============================================================
// location_screen.dart — GPS location display and sharing
//   Now streams live GPS updates via Geolocator.getPositionStream()
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();

  LocationResult? _locationResult;
  bool _isLoading = false;
  String _permissionStatus = 'Checking…';

  // ─── Real-time stream state ──────────────────────────────────
  StreamSubscription<LocationResult>? _locationSub;
  bool _isLiveTracking = false;
  DateTime? _lastUpdated;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Ticking "updated X seconds ago" timer
  Timer? _agoTimer;
  String _agoText = '';

  @override
  void initState() {
    super.initState();

    // Pulsing animation for LIVE badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermissionAndStart();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _agoTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Permission & Auto-Start ─────────────────────────────────

  Future<void> _checkPermissionAndStart() async {
    final status = await _locationService.getPermissionStatus();
    if (mounted) setState(() => _permissionStatus = status);

    if (status.contains('Granted')) {
      _startLiveTracking();
    }
  }

  // ─── Live Tracking ───────────────────────────────────────────

  void _startLiveTracking() {
    if (_isLiveTracking) return;

    setState(() {
      _isLiveTracking = true;
      _isLoading = true;
    });

    _locationSub = _locationService
        .getLocationStream(intervalMs: 5000)
        .listen(
      (result) {
        if (!mounted) return;
        setState(() {
          _locationResult = result;
          _isLoading = false;
          _lastUpdated = DateTime.now();
          _agoText = 'Just now';
        });
        _refreshPermissionStatus();
        _startAgoTimer();
      },
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _stopLiveTracking() {
    _locationSub?.cancel();
    _locationSub = null;
    _agoTimer?.cancel();
    if (mounted) {
      setState(() {
        _isLiveTracking = false;
        _agoText = '';
      });
    }
  }

  /// Updates the "X seconds ago" text every second
  void _startAgoTimer() {
    _agoTimer?.cancel();
    _agoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lastUpdated == null) return;
      final diff = DateTime.now().difference(_lastUpdated!).inSeconds;
      String text;
      if (diff < 5) {
        text = 'Just now';
      } else if (diff < 60) {
        text = '$diff seconds ago';
      } else {
        text = '${diff ~/ 60}m ago';
      }
      setState(() => _agoText = text);
    });
  }

  Future<void> _refreshPermissionStatus() async {
    final status = await _locationService.getPermissionStatus();
    if (mounted) setState(() => _permissionStatus = status);
  }

  Future<void> _requestPermission() async {
    final granted = await _locationService.requestPermission();
    if (granted) {
      _startLiveTracking();
    } else {
      final status = await _locationService.getPermissionStatus();
      if (mounted) {
        setState(() => _permissionStatus = status);
        if (status.contains('permanently')) {
          _showOpenSettingsDialog();
        }
      }
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppColors.sosRed),
            SizedBox(width: 8),
            Text('Permission Required',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Location permission was permanently denied.\n\n'
          'Please open Settings → App Permissions → Location and allow access.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _locationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps() async {
    if (_locationResult?.hasLocation != true) return;
    final url = _locationResult!.mapsUrl;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open Maps. Make sure a maps app is installed.');
      }
    } catch (e) {
      _showError('Unable to open Maps: ${e.toString()}');
    }
  }

  Future<void> _shareLocation() async {
    if (_locationResult?.hasLocation != true) return;
    final url = _locationResult!.mapsUrl;
    final shareText = 'My current location: $url';
    final shareUri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
    try {
      if (await canLaunchUrl(shareUri)) {
        await launchUrl(shareUri, mode: LaunchMode.externalApplication);
      } else {
        await _copyToClipboard(url, 'Location link copied to clipboard!');
      }
    } catch (_) {
      await _copyToClipboard(url, 'Location link copied to clipboard!');
    }
  }

  Future<void> _copyCoords() async {
    if (_locationResult?.hasLocation != true) return;
    await _copyToClipboard(
        _locationResult!.coordString, 'Coordinates copied!');
  }

  Future<void> _copyToClipboard(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 $msg'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.sosRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission status card
            _permissionCard(),

            const SizedBox(height: 20),

            // Location display card (with live badge)
            _locationCard(),

            const SizedBox(height: 20),

            // Action buttons
            if (_locationResult?.hasLocation == true) ...[
              _buildActionButton(
                icon: Icons.map_rounded,
                label: 'Open in Google Maps',
                color: AppColors.accentBlue,
                onTap: _openInMaps,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Share Location',
                color: AppColors.accentGreen,
                onTap: _shareLocation,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy Coordinates',
                color: AppColors.accentOrange,
                onTap: _copyCoords,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 4),

            // Live Tracking toggle button
            SizedBox(
              width: double.infinity,
              child: _isLiveTracking
                  ? OutlinedButton.icon(
                      onPressed: _stopLiveTracking,
                      icon: const Icon(Icons.stop_circle_outlined,
                          color: AppColors.sosRed),
                      label: const Text(
                        'Stop Live Tracking',
                        style: TextStyle(color: AppColors.sosRed),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sosRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startLiveTracking,
                      icon: const Icon(Icons.my_location_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Start Live Tracking',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard() {
    final isGranted = _permissionStatus.contains('Granted');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? AppColors.accentGreen.withOpacity(0.08)
                  : AppColors.sosRed.withOpacity(0.08),
            ),
            child: Icon(
              isGranted ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: isGranted ? AppColors.accentGreen : AppColors.sosRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location Permission',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(_permissionStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: isGranted
                          ? AppColors.accentGreen
                          : AppColors.sosRed,
                    )),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: _requestPermission,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.sosRed,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              child: const Text('Allow'),
            ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          // Map pin icon + LIVE badge row
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _locationResult?.hasLocation == true
                      ? AppColors.accentGreen.withOpacity(0.08)
                      : AppColors.sosRed.withOpacity(0.06),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: _locationResult?.hasLocation == true
                      ? AppColors.accentGreen
                      : AppColors.sosRed.withOpacity(0.6),
                ),
              ),
              // LIVE badge (only when streaming)
              if (_isLiveTracking)
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '● LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Column(
              children: [
                CircularProgressIndicator(color: AppColors.sosRed),
                SizedBox(height: 12),
                Text('Acquiring GPS signal…',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            )
          else if (_locationResult == null)
            const Column(
              children: [
                Text(
                  'Live tracking not started',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap "Start Live Tracking" to stream\nyour GPS coordinates in real time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ],
            )
          else if (_locationResult!.hasLocation)
            Column(
              children: [
                const Text('Current Location',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _copyCoords,
                  child: Text(
                    _locationResult!.coordString,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap coordinates to copy',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                // "Last updated X seconds ago"
                if (_agoText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.update_rounded,
                            size: 12, color: AppColors.accentGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Updated $_agoText',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.accentGreen),
                      SizedBox(width: 4),
                      Text('Location retrieved',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 36, color: AppColors.sosRed),
                const SizedBox(height: 8),
                Text(
                  _locationResult!.error ?? 'Location unavailable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.sosRed,
                      height: 1.5),
                ),
                if (_locationResult!.permissionDenied) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sosRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Grant Permission',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
