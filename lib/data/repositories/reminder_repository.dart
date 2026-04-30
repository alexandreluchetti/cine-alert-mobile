import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/reminder_entity.dart';
import '../../domain/entities/content_entity.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(dioProvider));
});

class ReminderRepository {
  final Dio _dio;

  ReminderRepository(this._dio);

  Future<List<ReminderEntity>> getReminders({String? status}) async {
    try {
      final params = status != null ? {'status': status} : null;
      final response = await _dio.get('/reminders', queryParameters: params);
      return (response.data as List).map((e) => _parseReminder(e)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<ReminderEntity> createReminder({
    required String contentId,
    required DateTime scheduledAt,
    required String recurrence,
    String? message,
  }) async {
    try {
      final response = await _dio.post('/reminders', data: {
        'contentId': contentId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'recurrence': recurrence,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      return _parseReminder(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<void> cancelReminder(String id) async {
    try {
      await _dio.delete('/reminders/$id');
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      final response = await _dio.get('/reminders/stats');
      return {
        'total': response.data['total'] ?? 0,
        'pending': response.data['pending'] ?? 0,
        'sent': response.data['sent'] ?? 0,
        'cancelled': response.data['cancelled'] ?? 0,
      };
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  ReminderEntity _parseReminder(Map<String, dynamic> data) {
    final contentData = data['content'] as Map<String, dynamic>;
    final content = ContentEntity(
      id: contentData['id'],
      imdbId: contentData['imdbId'] ?? '',
      title: contentData['title'] ?? '',
      type: contentData['type'] ?? 'MOVIE',
      posterUrl: contentData['posterUrl'],
      year: contentData['year'],
      rating: contentData['rating'] != null ? double.tryParse(contentData['rating'].toString()) : null,
      genre: contentData['genre'],
    );

    final statusStr = (data['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final recurrenceStr = (data['recurrence'] as String?)?.toUpperCase() ?? 'ONCE';

    return ReminderEntity(
      id: data['id'],
      content: content,
      scheduledAt: DateTime.parse(data['scheduledAt']),
      recurrence: Recurrence.values.firstWhere(
        (r) => r.name.toUpperCase() == recurrenceStr,
        orElse: () => Recurrence.once,
      ),
      message: data['message'],
      status: ReminderStatus.values.firstWhere(
        (s) => s.name.toUpperCase() == statusStr,
        orElse: () => ReminderStatus.pending,
      ),
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null,
    );
  }
}
