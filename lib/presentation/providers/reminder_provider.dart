import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/notifications/notification_service.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../data/repositories/reminder_repository.dart';

class ReminderNotifier extends StateNotifier<AsyncValue<List<ReminderEntity>>> {
  final ReminderRepository _repository;

  // Token reutilizável: substituído a cada loadReminders para cancelar a carga anterior.
  CancelToken _cancelToken = CancelToken();

  ReminderNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadReminders({ReminderStatus? status}) async {
    // Cancela requisição anterior antes de iniciar a nova.
    _cancelToken.cancel();
    _cancelToken = CancelToken();

    state = const AsyncValue.loading();
    try {
      final statusStr = status?.name.toUpperCase();
      final reminders = await _repository.getReminders(
        status: statusStr,
        cancelToken: _cancelToken,
      );
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      // Cancelamento intencional — sai silenciosamente sem alterar a UI.
      if (e is AppException && e.isCancelled) return;
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
      final newReminder = await _repository.createReminder(
        contentId: contentId,
        scheduledAt: scheduledAt,
        recurrence: recurrence,
        message: message,
      );

      await NotificationService.instance.scheduleReminder(
        id: newReminder.id.hashCode,
        title: 'CineAlert: Lembrete!',
        body: newReminder.message?.isNotEmpty == true
            ? newReminder.message!
            : 'Seu lembrete para assistir ${newReminder.content.title} chegou!',
        scheduledAt: scheduledAt,
      );

      await loadReminders();
      return true;
    } catch (e) {
      if (e is AppException && e.isCancelled) return false;
      return false;
    }
  }

  Future<bool> cancelReminder(String id) async {
    try {
      await _repository.cancelReminder(id);
      await NotificationService.instance.cancelReminder(id.hashCode);
      await loadReminders();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<List<ReminderEntity>>>(
        (ref) {
  return ReminderNotifier(ref.watch(reminderRepositoryProvider));
});

final reminderStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(reminderRepositoryProvider).getStats();
});
