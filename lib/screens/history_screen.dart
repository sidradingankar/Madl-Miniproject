// ============================================================
// history_screen.dart — SOS alert history log
//   Now auto-refreshes in real time via AppEventBus
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sos_record_model.dart';
import '../services/storage_service.dart';
import '../services/sos_service.dart';
import '../services/event_bus.dart';
import '../utils/constants.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final SosService _sosService = SosService();
  List<SosRecordModel> _records = [];
  bool _isLoading = true;

  // ─── Real-time event bus subscription ───────────────────────
  late final StreamSubscription<SosRecordModel> _sosSub;
  bool _justUpdated = false;
  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    // Flash animation for the "Updated just now" banner
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnimation = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    );

    _loadHistory();

    // Subscribe — auto-refresh whenever a new SOS is saved
    _sosSub = AppEventBus.instance.sosStream.listen((newRecord) {
      if (!mounted) return;
      _loadHistory(showFlash: true);
    });
  }

  @override
  void dispose() {
    _sosSub.cancel(); // prevent memory leak
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showFlash = false}) async {
    setState(() => _isLoading = true);
    final records = await _storage.getSosHistory();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
        if (showFlash) _justUpdated = true;
      });
      if (showFlash) {
        _flashController.forward(from: 0);
        // Hide the banner after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _justUpdated = false);
            _flashController.reverse();
          }
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear History?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'This will permanently delete all SOS alert records. '
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearSosHistory();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS history cleared.'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openMap(SosRecordModel record) async {
    if (record.mapsUrl == null) return;
    final opened = await _sosService.openMapsUrl(record.mapsUrl!);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Maps app.'),
          backgroundColor: AppColors.sosRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── "Updated just now" real-time banner ──────────────
          FadeTransition(
            opacity: _flashAnimation,
            child: _justUpdated
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: AppColors.accentGreen.withOpacity(0.12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sync_rounded,
                            size: 15, color: AppColors.accentGreen),
                        SizedBox(width: 6),
                        Text(
                          '⚡ History updated in real time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ─── Main body ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sosRed))
                : _records.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: AppColors.sosRed,
                        child: ListView(
                          padding:
                              const EdgeInsets.only(top: 12, bottom: 100),
                          children: [
                            // Summary chip row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  _summaryChip(
                                    label: '${_records.length} total',
                                    icon: Icons.history_rounded,
                                    color: AppColors.accentBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  _summaryChip(
                                    label:
                                        '${_records.where((r) => r.status.contains('Sent')).length} sent',
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.accentGreen,
                                  ),
                                  const Spacer(),
                                  // Live indicator dot
                                  _liveIndicator(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // History cards
                            for (final record in _records)
                              HistoryCard(
                                record: record,
                                onOpenMap: record.hasLocation
                                    ? () => _openMap(record)
                                    : null,
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      // Clear history FAB (only shown when there are records)
      floatingActionButton: _records.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _clearHistory,
              backgroundColor: AppColors.sosRed,
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.white),
              label: const Text(
                'Clear History',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  // ─── Live indicator ──────────────────────────────────────────

  Widget _liveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accentGreen.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: AppColors.accentGreen),
          SizedBox(width: 4),
          Text('LIVE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentGreen,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _summaryChip(
      {required String label,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 80, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No SOS Alerts Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your SOS alert history will appear here\nafter you activate an emergency alert.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing dot widget ──────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
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
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
