import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

final notificationProvider = StreamProvider<List<AppNotification>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return Stream.value([]);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at')
      .map((data) => data.map((json) => AppNotification.fromJson(json)).toList().reversed.toList());
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

class NotificationService {
  final _supabase = Supabase.instance.client;

  Future<void> markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? orderId,
    String? type,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'order_id': orderId,
      'type': type,
    });
  }
}
