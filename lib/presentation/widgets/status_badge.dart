import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/reminder_entity.dart';

class StatusBadge extends StatelessWidget {
  final ReminderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ReminderStatus.pending => (AppColors.statusPending, 'Pendente'),
      ReminderStatus.sent => (AppColors.statusSent, 'Enviado'),
      ReminderStatus.cancelled => (AppColors.statusCancelled, 'Cancelado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
