// ============================================================
// storage_service.dart — SharedPreferences + JSON storage
//   Works on Android, iOS AND Flutter Web (Chrome)
//   SQLite was removed because sqflite has no web support.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../models/sos_record_model.dart';

class StorageService {
  // Singleton pattern — only one instance throughout the app
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // SharedPreferences keys
  static const _contactsKey = 'contacts_json';
  static const _sosHistoryKey = 'sos_history_json';
  static const _nextContactIdKey = 'next_contact_id';
  static const _nextSosIdKey = 'next_sos_id';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // ─── Helpers ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(list));
  }

  Future<int> _nextId(String key) async {
    final prefs = await _prefs;
    final id = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, id);
    return id;
  }

  // ─── Default Contacts Seeding ────────────────────────────────

  Future<void> _seedDefaultContactsIfNeeded() async {
    final prefs = await _prefs;
    final seeded = prefs.getBool('contacts_seeded') ?? false;
    if (seeded) return;

    final defaults = [
      ContactModel(id: 1, name: 'Mom', phone: '+919876543210', relationship: 'Mother', isEmergency: true),
      ContactModel(id: 2, name: 'Dad', phone: '+919876543211', relationship: 'Father', isEmergency: true),
      ContactModel(id: 3, name: 'Dr. Kumar', phone: '+919876543212', relationship: 'Family Doctor', isEmergency: true),
    ];

    await _writeList(_contactsKey, defaults.map((c) => c.toMap()).toList());
    await prefs.setInt(_nextContactIdKey, 3);
    await prefs.setBool('contacts_seeded', true);
  }

  // ─── Contact CRUD ────────────────────────────────────────────

  /// Get all contacts
  Future<List<ContactModel>> getContacts() async {
    await _seedDefaultContactsIfNeeded();
    final list = await _readList(_contactsKey);
    final contacts = list.map((m) => ContactModel.fromMap(m)).toList();
    contacts.sort((a, b) => a.name.compareTo(b.name));
    return contacts;
  }

  /// Get only emergency-flagged contacts
  Future<List<ContactModel>> getEmergencyContacts() async {
    final all = await getContacts();
    return all.where((c) => c.isEmergency).toList();
  }

  /// Insert a new contact
  Future<int> insertContact(ContactModel contact) async {
    final id = await _nextId(_nextContactIdKey);
    final list = await _readList(_contactsKey);
    final updated = ContactModel(
      id: id,
      name: contact.name,
      phone: contact.phone,
      relationship: contact.relationship,
      isEmergency: contact.isEmergency,
    );
    list.add(updated.toMap());
    await _writeList(_contactsKey, list);
    return id;
  }

  /// Update an existing contact
  Future<int> updateContact(ContactModel contact) async {
    final list = await _readList(_contactsKey);
    final idx = list.indexWhere((m) => m['id'] == contact.id);
    if (idx == -1) return 0;
    list[idx] = contact.toMap();
    await _writeList(_contactsKey, list);
    return 1;
  }

  /// Delete a contact by id
  Future<int> deleteContact(int id) async {
    final list = await _readList(_contactsKey);
    final filtered = list.where((m) => m['id'] != id).toList();
    await _writeList(_contactsKey, filtered);
    return 1;
  }

  // ─── SOS History CRUD ────────────────────────────────────────

  /// Get all SOS records, newest first
  Future<List<SosRecordModel>> getSosHistory() async {
    final list = await _readList(_sosHistoryKey);
    final records = list.map((m) => SosRecordModel.fromMap(m)).toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  /// Insert a new SOS record
  Future<int> insertSosRecord(SosRecordModel record) async {
    final id = await _nextId(_nextSosIdKey);
    final list = await _readList(_sosHistoryKey);
    final updated = SosRecordModel(
      id: id,
      timestamp: record.timestamp,
      latitude: record.latitude,
      longitude: record.longitude,
      status: record.status,
      contactsNotified: record.contactsNotified,
      isDemoMode: record.isDemoMode,
    );
    list.add(updated.toMap());
    await _writeList(_sosHistoryKey, list);
    return id;
  }

  /// Delete all SOS history
  Future<void> clearSosHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_sosHistoryKey);
    await prefs.remove(_nextSosIdKey);
  }

  // ─── Settings via SharedPreferences ─────────────────────────

  /// SOS countdown duration in seconds (default: 5)
  Future<int> getCountdownDuration() async {
    final prefs = await _prefs;
    return prefs.getInt('countdown_duration') ?? 5;
  }

  Future<void> setCountdownDuration(int seconds) async {
    final prefs = await _prefs;
    await prefs.setInt('countdown_duration', seconds);
  }

  /// Whether Demo Mode is enabled (default: true for safety)
  Future<bool> getDemoMode() async {
    final prefs = await _prefs;
    return prefs.getBool('demo_mode') ?? true;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('demo_mode', value);
  }

  /// Whether to require confirmation before SOS (default: true)
  Future<bool> getRequireConfirmation() async {
    final prefs = await _prefs;
    return prefs.getBool('require_confirmation') ?? true;
  }

  Future<void> setRequireConfirmation(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool('require_confirmation', value);
  }

  /// First launch check — returns true if app launched for the first time
  Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    final launched = prefs.getBool('launched_before') ?? false;
    if (!launched) {
      await prefs.setBool('launched_before', true);
    }
    return !launched;
  }
}
