// ============================================================
// contacts_screen.dart — Emergency contacts management
// ============================================================

import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/contact_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final StorageService _storage = StorageService();
  List<ContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _storage.getContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  // ─── Add / Edit Dialog ──────────────────────────────────────

  Future<void> _showContactDialog({ContactModel? existing}) async {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final relationCtrl =
        TextEditingController(text: existing?.relationship ?? '');
    bool isEmergency = existing?.isEmergency ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'Add Contact' : 'Edit Contact',
            style: AppTextStyles.screenTitle,
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDecoration('Full Name', Icons.person),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),

                  // Phone field
                  TextFormField(
                    controller: phoneCtrl,
                    decoration:
                        _inputDecoration('Phone Number', Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      // Basic validation: must have at least 7 digits
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Relationship field
                  TextFormField(
                    controller: relationCtrl,
                    decoration: _inputDecoration(
                        'Relationship (e.g. Mother)', Icons.people),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Relationship is required'
                            : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),

                  // Emergency contact toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sos_rounded,
                            size: 18, color: AppColors.sosRed),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Mark as Emergency Contact',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: isEmergency,
                          onChanged: (v) =>
                              setDialogState(() => isEmergency = v),
                          activeTrackColor: AppColors.sosRed,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final contact = ContactModel(
                  id: existing?.id,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  relationship: relationCtrl.text.trim(),
                  isEmergency: isEmergency,
                );

                if (existing == null) {
                  await _storage.insertContact(contact);
                } else {
                  await _storage.updateContact(contact);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
                await _loadContacts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                existing == null ? 'Add' : 'Save',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.sosRed, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ─── Delete Confirmation ─────────────────────────────────────

  Future<void> _confirmDelete(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${contact.name}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
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
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && contact.id != null) {
      await _storage.deleteContact(contact.id!);
      await _loadContacts();
    }
  }

  // ─── Toggle emergency status ─────────────────────────────────

  Future<void> _toggleEmergency(ContactModel contact, bool value) async {
    await _storage.updateContact(contact.copyWith(isEmergency: value));
    await _loadContacts();
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sosRed))
          : _contacts.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadContacts,
                  color: AppColors.sosRed,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    children: [
                      // Info banner
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.accentBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_contacts.where((c) => c.isEmergency).length} '
                                  'emergency contact(s) will receive SOS alerts.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Contact cards
                      for (final contact in _contacts)
                        ContactCard(
                          contact: contact,
                          onEdit: () =>
                              _showContactDialog(existing: contact),
                          onDelete: () => _confirmDelete(contact),
                          onToggleEmergency: (v) =>
                              _toggleEmergency(contact, v),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppColors.sosRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Contact',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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
            Icon(Icons.contacts_outlined,
                size: 80, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No Contacts Yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add emergency contacts who will\nreceive your SOS alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showContactDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add First Contact',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosRed,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
