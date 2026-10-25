// ============================================================
// contact_card.dart — Card widget for a single emergency contact
// ============================================================

import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../utils/constants.dart';

class ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEmergency;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEmergency,
  });

  // Avatar color based on first letter
  Color _avatarColor() {
    const colors = [
      Color(0xFFD32F2F),
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
    ];
    final index = contact.name.isEmpty
        ? 0
        : contact.name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppDecorations.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar circle with initial
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarColor(),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty
                      ? contact.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name, phone, relationship
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: AppTextStyles.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.isEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sosRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.sosRed.withOpacity(0.25)),
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sosRed,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(contact.phone, style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 2),
                  Text(
                    contact.relationship,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: AppColors.accentBlue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                // Toggle emergency switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: contact.isEmergency,
                    onChanged: onToggleEmergency,
                    activeTrackColor: AppColors.sosRed,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.accentBlue),
                      ),
                    ),
                    // Delete
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: AppColors.sosRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
