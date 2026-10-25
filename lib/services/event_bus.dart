// ============================================================
// event_bus.dart — App-wide broadcast stream for SOS events
// ============================================================
//
// Usage:
//   Fire:   AppEventBus.instance.fireSos(record);
//   Listen: AppEventBus.instance.sosStream.listen((record) { … });
// ============================================================

import '../models/sos_record_model.dart';
import 'dart:async';

class AppEventBus {
  // Singleton
  static final AppEventBus instance = AppEventBus._internal();
  AppEventBus._internal();

  // Broadcast controller — multiple listeners allowed
  final _sosController = StreamController<SosRecordModel>.broadcast();

  /// Stream that emits a [SosRecordModel] whenever an SOS is saved.
  Stream<SosRecordModel> get sosStream => _sosController.stream;

  /// Call this after an SOS record is saved to notify all listeners.
  void fireSos(SosRecordModel record) {
    if (!_sosController.isClosed) {
      _sosController.add(record);
    }
  }

  /// Call on app shutdown (optional cleanup).
  void dispose() {
    _sosController.close();
  }
}
