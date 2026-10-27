// ============================================================
// native_channel_service.dart — Platform channel bridge for
//   direct SMS, direct calls, and volume button events
// ============================================================

import 'dart:async';
import 'package:flutter/services.dart';

class NativeChannelService {
  // Singleton
  static final NativeChannelService _instance = NativeChannelService._internal();
  factory NativeChannelService() => _instance;
  NativeChannelService._internal();

  // Must match the channel names in MainActivity.kt
  static const _methodChannel =
      MethodChannel('com.madl.emergency_assistance/native');
  static const _eventChannel =
      EventChannel('com.madl.emergency_assistance/volume_events');

  // ─── Volume Button Event Stream ──────────────────────────────

  /// Stream that emits "SOS_TRIGGERED" when the user presses
  /// volume-down 3 times within 2 seconds.
  Stream<String> get volumeButtonStream =>
      _eventChannel.receiveBroadcastStream().map((event) => event.toString());

  // ─── Direct SMS ──────────────────────────────────────────────

  /// Send an SMS directly (no SMS app opened).
  /// Returns true if sent successfully.
  Future<bool> sendDirectSms({
    required String phone,
    required String message,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendSms',
        {'phone': phone, 'message': message},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('SMS send error: ${e.message}');
      return false;
    }
  }

  // ─── Direct Phone Call ───────────────────────────────────────

  /// Make a direct phone call (no dialer opened — call starts immediately).
  /// Returns true if call was initiated.
  Future<bool> makeDirectCall({required String phone}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'makeCall',
        {'phone': phone},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Call error: ${e.message}');
      return false;
    }
  }

  // ─── Permission Requests ─────────────────────────────────────

  /// Request SMS permission from the user
  Future<void> requestSmsPermission() async {
    try {
      await _methodChannel.invokeMethod('requestSmsPermission');
    } catch (_) {}
  }

  /// Request phone call permission from the user
  Future<void> requestCallPermission() async {
    try {
      await _methodChannel.invokeMethod('requestCallPermission');
    } catch (_) {}
  }

  /// Check current permission status
  /// Returns {'sms': bool, 'call': bool}
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result =
          await _methodChannel.invokeMethod<Map<Object?, Object?>>('checkPermissions');
      if (result != null) {
        return {
          'sms': result['sms'] as bool? ?? false,
          'call': result['call'] as bool? ?? false,
        };
      }
    } catch (_) {}
    return {'sms': false, 'call': false};
  }
}
