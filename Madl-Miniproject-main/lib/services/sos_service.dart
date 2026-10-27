// ============================================================
// sos_service.dart — Orchestrates the SOS emergency flow
//   Sends SMS directly + makes emergency call + saves to history
// ============================================================

import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../models/sos_record_model.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'event_bus.dart';
import 'native_channel_service.dart';

/// Result returned after an SOS attempt
class SosResult {
  final bool success;
  final String message;
  final LocationResult? locationResult;
  final int contactsNotified;
  final int contactsCalled;
  final SosRecordModel? savedRecord;

  const SosResult({
    required this.success,
    required this.message,
    this.locationResult,
    this.contactsNotified = 0,
    this.contactsCalled = 0,
    this.savedRecord,
  });
}

class SosService {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final NativeChannelService _nativeService = NativeChannelService();

  // ─── Main SOS Trigger ───────────────────────────────────────

  /// Full SOS flow:
  /// 1. Get GPS location
  /// 2. Load emergency contacts
  /// 3. Send SMS directly to all contacts (no SMS app opened)
  /// 4. Call the first emergency contact directly
  /// 5. Save to history
  Future<SosResult> triggerSOS() async {
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
    int called = 0;
    String resultMessage;

    if (contacts.isEmpty) {
      resultMessage = '⚠️ No emergency contacts found. Please add emergency contacts first.';
    } else {
      // Send SMS directly to each contact (background, no SMS app opened)
      notified = await _sendDirectSMS(contacts, message);

      // Call the first emergency contact directly
      if (contacts.isNotEmpty) {
        final callSuccess = await _nativeService.makeDirectCall(
          phone: contacts.first.phone,
        );
        if (callSuccess) called = 1;
      }

      // Build result message
      final smsPart = notified > 0
          ? '✅ SMS sent to $notified contact(s)'
          : '⚠️ Could not send SMS (check SMS permission)';
      final callPart = called > 0
          ? '📞 Calling ${contacts.first.name}…'
          : '';
      resultMessage = '$smsPart${callPart.isNotEmpty ? '\n$callPart' : ''}';
    }

    // Step 4: Save SOS record to history
    final record = SosRecordModel(
      timestamp: DateTime.now(),
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      status: contacts.isEmpty ? 'No Contacts' : 'Alert Sent',
      contactsNotified: notified,
      isDemoMode: false,
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
      contactsCalled: called,
      savedRecord: savedRecord,
    );
  }

  // ─── Direct SMS via Native Platform Channel ──────────────────

  /// Sends SMS directly to each contact using Android's SmsManager.
  /// No SMS app is opened — messages are sent silently in the background.
  /// Returns the count of successfully sent messages.
  Future<int> _sendDirectSMS(
      List<ContactModel> contacts, String message) async {
    int count = 0;
    for (final contact in contacts) {
      final success = await _nativeService.sendDirectSms(
        phone: contact.phone,
        message: message,
      );
      if (success) count++;
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
