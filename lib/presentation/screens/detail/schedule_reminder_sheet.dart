import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/content_entity.dart';
import '../../../domain/entities/reminder_entity.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/cinealert_button.dart';

class ScheduleReminderSheet extends ConsumerStatefulWidget {
  final ContentEntity content;

  const ScheduleReminderSheet({super.key, required this.content});

  @override
  ConsumerState<ScheduleReminderSheet> createState() => _ScheduleReminderSheetState();
}

class _ScheduleReminderSheetState extends ConsumerState<ScheduleReminderSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  Recurrence _recurrence = Recurrence.once;
  final _messageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_combinedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma data/hora futura'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);

    final recurrenceStr = _recurrence.name.toUpperCase();

    final success = await ref.read(reminderProvider.notifier).createReminder(
      contentId: widget.content.id!,
      scheduledAt: _combinedDateTime,
      recurrence: recurrenceStr,
      message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✅ Lembrete criado!' : '❌ Erro ao criar lembrete'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat.jm('pt_BR');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Movie preview
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.content.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.content.posterUrl!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56, height: 80,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.movie, color: AppColors.textDisabled),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agendar lembrete',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      widget.content.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date + Time pickers
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: dateFormat.format(_selectedDate),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerButton(
                  icon: Icons.access_time_rounded,
                  label: 'Hora',
                  value: _selectedTime.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recurrence chips
          const Text('Recorrência', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Recurrence.values.map((r) {
              final label = switch (r) {
                Recurrence.once => 'Uma vez',
                Recurrence.daily => 'Diário',
                Recurrence.weekly => 'Semanal',
              };
              return ChoiceChip(
                label: Text(label),
                selected: _recurrence == r,
                onSelected: (_) => setState(() => _recurrence = r),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: _recurrence == r ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom message
          TextFormField(
            controller: _messageCtrl,
            maxLength: 255,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter'),
            decoration: const InputDecoration(
              labelText: 'Mensagem personalizada (opcional)',
              prefixIcon: Icon(Icons.message_outlined, color: AppColors.textSecondary, size: 20),
              counterStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),

          CineAlertButton(
            label: 'Salvar Lembrete',
            isLoading: _saving,
            onPressed: _save,
            icon: Icons.alarm_add_rounded,
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text(value, style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14,
                  )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
          ],
        ),
      ),
    );
  }
}
