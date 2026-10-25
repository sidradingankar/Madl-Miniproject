// ============================================================
// history_card.dart — Card widget for a single SOS history record
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sos_record_model.dart';
import '../utils/constants.dart';

class HistoryCard extends StatelessWidget {
  final SosRecordModel record;
  final VoidCallback? onOpenMap;

  const HistoryCard({
    super.key,
    required this.record,
    this.onOpenMap,
  });

  // Status color based on record status
  Color get _statusColor {
    if (record.status.contains('Sent')) return AppColors.accentGreen;
    if (record.status.contains('Cancelled')) return AppColors.textSecondary;
    if (record.status.contains('No Contacts')) return AppColors.accentOrange;
    return AppColors.accentBlue;
  }

  IconData get _statusIcon {
    if (record.status.contains('Sent')) return Icons.check_circle_rounded;
    if (record.status.contains('Cancelled')) return Icons.cancel_rounded;
    if (record.status.contains('No Contacts')) return Icons.warning_rounded;
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(record.timestamp);
    final timeStr = DateFormat('hh:mm a').format(record.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppDecorations.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: SOS Alert title + demo badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sosRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sos_rounded,
                          size: 16, color: AppColors.sosRed),
                      SizedBox(width: 4),
                      Text(
                        'SOS Alert',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sosRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (record.isDemoMode)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const Spacer(),
                // Status icon
                Icon(_statusIcon, size: 20, color: _statusColor),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(dateStr, style: AppTextStyles.cardSubtitle),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_rounded,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(timeStr, style: AppTextStyles.cardSubtitle),
              ],
            ),

            const SizedBox(height: 8),

            // Location info
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.hasLocation
                        ? '${record.latitude!.toStringAsFixed(5)}, '
                            '${record.longitude!.toStringAsFixed(5)}'
                        : 'Location unavailable',
                    style: AppTextStyles.cardSubtitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Contacts notified
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${record.contactsNotified} contact(s) notified',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status chip + optional map button
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                // View on map button (only if location available)
                if (record.hasLocation && onOpenMap != null)
                  TextButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('View Map'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to check if record has valid location
extension SosRecordExt on SosRecordModel {
  bool get hasLocation => latitude != null && longitude != null;
}
