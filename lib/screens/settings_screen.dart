// ============================================================
// settings_screen.dart — App settings and configuration
// ============================================================

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final LocationService _locationService = LocationService();

  int _countdownDuration = 5;
  bool _demoMode = true;
  bool _requireConfirmation = true;
  String _locationPermissionStatus = 'Checking…';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await _storage.getCountdownDuration();
    final demo = await _storage.getDemoMode();
    final confirm = await _storage.getRequireConfirmation();
    final locStatus = await _locationService.getPermissionStatus();

    if (mounted) {
      setState(() {
        _countdownDuration = duration;
        _demoMode = demo;
        _requireConfirmation = confirm;
        _locationPermissionStatus = locStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndNotify() async {
    widget.onSettingsChanged?.call();
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.sosRed));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SOS Configuration ──────────────────────────────
          _sectionHeader('SOS Configuration', Icons.sos_rounded),
          const SizedBox(height: 8),

          _settingsCard(children: [
            // Demo mode toggle
            _switchTile(
              icon: Icons.science_rounded,
              iconColor: Colors.amber,
              title: 'Demo Mode',
              subtitle: 'Simulate SOS alert without sending real SMS',
              value: _demoMode,
              onChanged: (val) async {
                setState(() => _demoMode = val);
                await _storage.setDemoMode(val);
                await _saveAndNotify();
              },
            ),

            const Divider(height: 1, indent: 56),

            // Require confirmation toggle
            _switchTile(
              icon: Icons.touch_app_rounded,
              iconColor: AppColors.accentBlue,
              title: 'Require Long Press',
              subtitle:
                  'Prevent accidental SOS — must hold button to activate',
              value: _requireConfirmation,
              onChanged: (val) async {
                setState(() => _requireConfirmation = val);
                await _storage.setRequireConfirmation(val);
                await _saveAndNotify();
              },
            ),

            const Divider(height: 1, indent: 56),

            // Countdown duration
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.sosRed.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_rounded,
                        size: 18, color: AppColors.sosRed),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOS Countdown Duration',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Seconds before alert is sent',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  // Duration selector
                  DropdownButton<int>(
                    value: _countdownDuration,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sosRed),
                    items: [3, 5, 10]
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('${s}s'),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      setState(() => _countdownDuration = val);
                      await _storage.setCountdownDuration(val);
                      await _saveAndNotify();
                    },
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Location ─────────────────────────────────────────
          _sectionHeader('Location', Icons.location_on_rounded),
          const SizedBox(height: 8),

          _settingsCard(children: [
            _actionTile(
              icon: Icons.gps_fixed_rounded,
              iconColor: AppColors.accentGreen,
              title: 'Permission Status',
              subtitle: _locationPermissionStatus,
              trailing: _locationPermissionStatus.contains('Granted')
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.accentGreen, size: 20)
                  : TextButton(
                      onPressed: () async {
                        await _locationService.requestPermission();
                        final status =
                            await _locationService.getPermissionStatus();
                        if (mounted) {
                          setState(
                              () => _locationPermissionStatus = status);
                        }
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.sosRed,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      child: const Text('Allow'),
                    ),
            ),

            const Divider(height: 1, indent: 56),

            _actionTile(
              icon: Icons.settings_rounded,
              iconColor: AppColors.accentBlue,
              title: 'Open Location Settings',
              subtitle: 'Change location permissions in device settings',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () => _locationService.openLocationSettings(),
            ),
          ]),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────
          _sectionHeader('About', Icons.info_rounded),
          const SizedBox(height: 8),

          _settingsCard(children: [
            _actionTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.accentBlue,
              title: 'About Application',
              subtitle: 'Version 1.0.0 — MADL Mini Project',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: _showAboutDialog,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.sosRed),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.sosRed,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Settings Card container ─────────────────────────────────
  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: AppDecorations.card,
      child: Column(
        children: children,
      ),
    );
  }

  // ─── Switch tile ─────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.sosRed,
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ─── Action tile ─────────────────────────────────────────────
  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // ─── About dialog ─────────────────────────────────────────────
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded,
                color: AppColors.sosRed, size: 28),
            SizedBox(width: 10),
            Text('Emergency Assistance',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Platform: Android (Flutter)',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 6),
            Text('Project: MADL Mini Project',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 16),
            Text(
              'This app allows you to quickly send SOS alerts '
              'to emergency contacts with your GPS location.',
              style: TextStyle(
                  color: AppColors.textSecondary, height: 1.6, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Features: SOS Button • Emergency Contacts • '
              'GPS Location • SOS History • Demo Mode',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
