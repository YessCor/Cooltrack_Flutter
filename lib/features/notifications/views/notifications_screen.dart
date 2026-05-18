import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No tienes notificaciones'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isRead ? AppColors.surfaceVariant : AppColors.secondary.withOpacity(0.1),
                  child: Icon(
                    _getIcon(notification.type),
                    color: notification.isRead ? AppColors.textMuted : AppColors.secondary,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(notification.message),
                trailing: Text(
                  _formatTime(notification.createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                onTap: () {
                  ref.read(notificationServiceProvider).markAsRead(notification.id);
                  if (notification.orderId != null) {
                    // Navegar según el rol (esto se puede mejorar con un detector de rol global)
                    context.push('/admin/orders/${notification.orderId}');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order': return Icons.assignment_outlined;
      case 'quote': return Icons.receipt_long_outlined;
      case 'alert': return Icons.warning_amber_outlined;
      default: return Icons.notifications_none_outlined;
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${date.day}/${date.month}';
  }
}
