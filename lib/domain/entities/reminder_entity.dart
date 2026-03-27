import 'content_entity.dart';

enum ReminderStatus { pending, sent, cancelled }
enum Recurrence { once, daily, weekly }

class ReminderEntity {
  final String id;
  final ContentEntity content;
  final DateTime scheduledAt;
  final Recurrence recurrence;
  final String? message;
  final ReminderStatus status;
  final DateTime? createdAt;

  const ReminderEntity({
    required this.id,
    required this.content,
    required this.scheduledAt,
    required this.recurrence,
    this.message,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == ReminderStatus.pending;
  bool get isSent => status == ReminderStatus.sent;
  bool get isCancelled => status == ReminderStatus.cancelled;
}
