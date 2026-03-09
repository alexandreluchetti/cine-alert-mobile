import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/reminder_entity.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/status_badge.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderProvider.notifier).loadReminders(status: _filterStatus);
    });
  }

  void _applyFilter(ReminderStatus? status) {
    setState(() => _filterStatus = status);
    ref.read(reminderProvider.notifier).loadReminders(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus Lembretes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildFilterChips(),
        ),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) return _buildEmpty(context);
          return _buildList(reminders);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _applyFilter(_filterStatus),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const options = [
      (null, 'Todos'),
      (ReminderStatus.pending, 'Pendentes'),
      (ReminderStatus.sent, 'Enviados'),
      (ReminderStatus.cancelled, 'Cancelados'),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: options.map((opt) {
          final (status, label) = opt;
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _applyFilter(status),
              selectedColor: AppColors.accent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(List<ReminderEntity> reminders) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref
          .read(reminderProvider.notifier)
          .loadReminders(status: _filterStatus),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _ReminderCard(
            reminder: reminder,
            onDelete: () => _confirmDelete(context, reminder),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_off_rounded,
                color: AppColors.textDisabled, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum lembrete ainda',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busque um filme e agende um lembrete!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ReminderEntity reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar lembrete'),
        content:
            Text('Deseja cancelar o lembrete de "${reminder.content.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(reminderProvider.notifier).cancelReminder(reminder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lembrete cancelado'),
              backgroundColor: AppColors.warning),
        );
      }
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderEntity reminder;
  final VoidCallback onDelete;

  const _ReminderCard({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Dismissible(
      key: Key('reminder-${reminder.id}'),
      direction: reminder.isPending
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: AppColors.error),
            SizedBox(height: 4),
            Text('Cancelar',
                style: TextStyle(color: AppColors.error, fontSize: 11)),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: reminder.content.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: reminder.content.posterUrl!,
                      width: 60,
                      height: 85,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 85,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.movie,
                          color: AppColors.textDisabled),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.content.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: AppColors.textSecondary, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          df.format(reminder.scheduledAt),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    if (reminder.recurrence != Recurrence.once) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.repeat,
                              color: AppColors.info, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            reminder.recurrence == Recurrence.daily
                                ? 'Diário'
                                : 'Semanal',
                            style: const TextStyle(
                                color: AppColors.info, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: StatusBadge(status: reminder.status),
            ),
          ],
        ),
      ),
    );
  }
}
