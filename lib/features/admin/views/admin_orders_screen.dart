import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/service_order.dart';

final ordersProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/orders');
  final List<dynamic> data = response['data'];
  return data.map((e) => ServiceOrder.fromJson(e)).toList();
});

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de Servicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No hay órdenes'))
            : RefreshIndicator(
                onRefresh: () async => ref.refresh(ordersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
                          child: Icon(
                            Icons.assignment,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        title: Text('Orden ${order.orderNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.serviceType),
                            Text(
                              order.address,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                        ),
                        onTap: () => context.go('/admin/orders/${order.id}'),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.assigned:
        return AppColors.statusAssigned;
      case OrderStatus.accepted:
        return AppColors.statusAccepted;
      case OrderStatus.inTransit:
        return AppColors.statusInTransit;
      case OrderStatus.inProgress:
        return AppColors.statusInProgress;
      case OrderStatus.completed:
        return AppColors.statusCompleted;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}