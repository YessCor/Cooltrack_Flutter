import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/api_client.dart';
import '../../../models/service_order.dart';
import '../../../models/equipment.dart';

final clientOrdersProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final api = ApiClient();
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  
  if (userId == null) return [];
  
  try {
    final response = await api.get('/orders', queryParams: {'client_id': userId});
    final data = response['data'] as List? ?? [];
    return data.map((json) => ServiceOrder.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

final clientEquipmentProvider = FutureProvider<List<Equipment>>((ref) async {
  final api = ApiClient();
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  
  if (userId == null) return [];
  
  try {
    final response = await api.get('/equipment', queryParams: {'client_id': userId});
    final data = response['data'] as List? ?? [];
    return data.map((json) => Equipment.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final ordersAsync = ref.watch(clientOrdersProvider);
    final equipmentAsync = ref.watch(clientEquipmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Casa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientOrdersProvider);
          ref.invalidate(clientEquipmentProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(user?.name ?? 'Cliente'),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildEquipmentSummary(equipmentAsync),
              const SizedBox(height: 24),
              _buildRecentServices(ordersAsync, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido,',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '¿En qué podemos ayudarte hoy?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Solicitar\nServicio',
                onTap: () => context.go('/client/new-request'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.hvac,
                label: 'Agregar\nEquipo',
                onTap: () => context.go('/client/equipment/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.history,
                label: 'Mis\nServicios',
                onTap: () => context.go('/client/new-request'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentSummary(AsyncValue<List<Equipment>> equipmentAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Equipos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        equipmentAsync.when(
          data: (equipment) => equipment.isEmpty
              ? _buildEmptyState(Icons.hvac, 'No tienes equipos registrados')
              : _buildEquipmentCard(equipment.first),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildEmptyState(Icons.error_outline, 'Error al cargar'),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hvac, color: AppColors.secondary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${equipment.typeLabel}${equipment.brand != null ? ' - ${equipment.brand}' : ''}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentServices(AsyncValue<List<ServiceOrder>> ordersAsync, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _buildEmptyState(Icons.receipt_long, 'No tienes servicios recientes');
            }
            return Column(
              children: orders.take(3).map((order) => _buildOrderCard(order, context)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildEmptyState(Icons.error_outline, 'Error al cargar'),
        ),
      ],
    );
  }

  Widget _buildOrderCard(ServiceOrder order, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/client/service/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(order.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        orderStatusLabels[status] ?? 'Desconocido',
        style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getStatusColor(status) {
    switch (status.toString()) {
      case 'OrderStatus.pending':
        return Colors.orange;
      case 'OrderStatus.assigned':
      case 'OrderStatus.accepted':
        return Colors.blue;
      case 'OrderStatus.inTransit':
      case 'OrderStatus.inProgress':
        return Colors.purple;
      case 'OrderStatus.completed':
        return Colors.green;
      case 'OrderStatus.cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(status) {
    switch (status.toString()) {
      case 'OrderStatus.pending':
        return Icons.hourglass_empty;
      case 'OrderStatus.assigned':
        return Icons.person;
      case 'OrderStatus.accepted':
        return Icons.check_circle_outline;
      case 'OrderStatus.inTransit':
        return Icons.directions_car;
      case 'OrderStatus.inProgress':
        return Icons.build;
      case 'OrderStatus.completed':
        return Icons.check_circle;
      case 'OrderStatus.cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}