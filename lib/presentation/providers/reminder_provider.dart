import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../data/repositories/reminder_repository.dart';

class ReminderNotifier extends StateNotifier<AsyncValue<List<ReminderEntity>>> {
  final ReminderRepository _repository;

  ReminderNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadReminders({ReminderStatus? status}) async {
    state = const AsyncValue.loading();
    try {
      final statusStr = status?.name.toUpperCase();
      final reminders = await _repository.getReminders(status: statusStr);
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createReminder({
    required String contentId,
    required DateTime scheduledAt,
    required String recurrence,
    String? message,
  }) async {
    try {
      await _repository.createReminder(
        contentId: contentId,
        scheduledAt: scheduledAt,
        recurrence: recurrence,
        message: message,
      );
      await loadReminders();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelReminder(String id) async {
    try {
      await _repository.cancelReminder(id);
      await loadReminders();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<List<ReminderEntity>>>((ref) {
  return ReminderNotifier(ref.watch(reminderRepositoryProvider));
});

final reminderStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(reminderRepositoryProvider).getStats();
});
