// ============================================================
// sos_service.dart — Orchestrates the SOS emergency flow
//   Now broadcasts a real-time event after each SOS save
// ============================================================

import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../models/sos_record_model.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'event_bus.dart';

/// Result returned after an SOS attempt
class SosResult {
  final bool success;
  final String message;
  final LocationResult? locationResult;
  final int contactsNotified;
  final bool isDemoMode;
  final SosRecordModel? savedRecord;

  const SosResult({
    required this.success,
    required this.message,
    this.locationResult,
    this.contactsNotified = 0,
    this.isDemoMode = false,
    this.savedRecord,
  });
}

class SosService {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  // ─── Main SOS Trigger ───────────────────────────────────────

  /// Full SOS flow:
  /// 1. Get GPS location
  /// 2. Load emergency contacts
  /// 3. Send alert (demo or real SMS)
  /// 4. Save to history
  Future<SosResult> triggerSOS() async {
    final isDemoMode = await _storageService.getDemoMode();

    // Step 1: Get current location
    final locationResult = await _locationService.getCurrentLocation();
    String locationText;
    if (locationResult.hasLocation) {
      locationText = locationResult.mapsUrl;
    } else {
      locationText = 'Location unavailable (${locationResult.error ?? "GPS off"})';
    }

    // Step 2: Build emergency message
    final message =
        'EMERGENCY! I need help. My current location is: $locationText. '
        'Please contact me immediately.';

    // Step 3: Load emergency contacts
    final contacts = await _storageService.getEmergencyContacts();

    int notified = 0;
    String resultMessage;

    if (contacts.isEmpty) {
      // No contacts — still save to history but warn the user
      resultMessage = isDemoMode
          ? '⚠️ No emergency contacts added. Add contacts in the Contacts screen.\n\n'
              'Demo message:\n$message'
          : '⚠️ No emergency contacts found. Please add emergency contacts first.';
    } else if (isDemoMode) {
      // Demo mode: simulate sending — show message, don't open SMS
      notified = contacts.length;
      resultMessage = '✅ Demo Alert Simulated!\n\n'
          'Would have been sent to ${contacts.length} contact(s):\n'
          '${contacts.map((c) => '• ${c.name} (${c.phone})').join('\n')}\n\n'
          'Message:\n"$message"';
    } else {
      // Real mode: open SMS app for each contact (url_launcher)
      notified = await _sendRealSMS(contacts, message);
      resultMessage = notified > 0
          ? '✅ SMS app opened for $notified contact(s). Send the pre-filled message.'
          : '⚠️ Could not open SMS app. Make sure an SMS app is installed.';
    }

    // Step 4: Save SOS record to history
    final record = SosRecordModel(
      timestamp: DateTime.now(),
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      status: contacts.isEmpty
          ? 'No Contacts'
          : (isDemoMode ? 'Demo Alert Sent' : 'Alert Sent'),
      contactsNotified: notified,
      isDemoMode: isDemoMode,
    );
    final savedId = await _storageService.insertSosRecord(record);
    final savedRecord = SosRecordModel(
      id: savedId,
      timestamp: record.timestamp,
      latitude: record.latitude,
      longitude: record.longitude,
      status: record.status,
      contactsNotified: record.contactsNotified,
      isDemoMode: record.isDemoMode,
    );

    // 🔴 Real-time broadcast — History screen will auto-update
    AppEventBus.instance.fireSos(savedRecord);

    return SosResult(
      success: true,
      message: resultMessage,
      locationResult: locationResult,
      contactsNotified: notified,
      isDemoMode: isDemoMode,
      savedRecord: savedRecord,
    );
  }

  // ─── Real SMS via url_launcher ──────────────────────────────

  /// Opens the native SMS app pre-filled for each emergency contact.
  /// Returns the count of successfully launched SMS intents.
  Future<int> _sendRealSMS(
      List<ContactModel> contacts, String message) async {
    int count = 0;
    for (final contact in contacts) {
      final encoded = Uri.encodeComponent(message);
      final smsUri = Uri.parse('sms:${contact.phone}?body=$encoded');
      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          count++;
        }
      } catch (_) {
        // Silently skip if SMS app not available for this contact
      }
    }
    return count;
  }

  // ─── Location-Only Fetch ───────────────────────────────────

  /// Get location without triggering a full SOS — used by location screen
  Future<LocationResult> getLocation() => _locationService.getCurrentLocation();

  // ─── Share Location ─────────────────────────────────────────

  /// Open Google Maps URL for a given location
  Future<bool> openMapsUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Share location via native share dialog (opens share sheet)
  Future<bool> shareLocationUrl(String url) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(url)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
