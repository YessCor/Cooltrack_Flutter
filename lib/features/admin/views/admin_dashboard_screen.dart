import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/dashboard_stats.dart';
import '../../../models/service_order.dart';
import '../../../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../../../components/sync_indicator.dart';

import '../../../components/sync_indicator.dart';
import '../../../providers/notification_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          const SyncIndicator(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(recentOrdersProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de Operaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              statsAsync.when(
                data: (stats) => _buildStatsGrid(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Órdenes Recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/admin/orders'),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentOrdersAsync.when(
                data: (orders) => _buildRecentOrdersList(context, orders),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Órdenes Totales',
          value: stats.totalOrders.toString(),
          icon: Icons.assignment_outlined,
          color: AppColors.secondary,
        ),
        _StatCard(
          title: 'Activas',
          value: stats.activeOrders.toString(),
          icon: Icons.engineering_outlined,
          color: AppColors.warning,
        ),
        _StatCard(
          title: 'Completadas',
          value: stats.completedOrders.toString(),
          icon: Icons.task_alt,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'Ingresos',
          value: stats.formattedRevenue,
          icon: Icons.payments_outlined,
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _QuickActionItem(
          icon: Icons.person_add_outlined,
          label: 'Cliente',
          onTap: () => context.go('/admin/clients/new'),
        ),
        _QuickActionItem(
          icon: Icons.engineering_outlined,
          label: 'Técnico',
          onTap: () => context.go('/admin/technicians/new'),
        ),
        _QuickActionItem(
          icon: Icons.receipt_long_outlined,
          label: 'Cotización',
          onTap: () => context.go('/admin/quotes/new'),
        ),
        _QuickActionItem(
          icon: Icons.list_alt_outlined,
          label: 'Catálogo',
          onTap: () => context.go('/admin/catalog'),
        ),
        _QuickActionItem(
          icon: Icons.map_outlined,
          label: 'Rastreo',
          onTap: () => context.go('/admin/tracking'),
        ),
        _QuickActionItem(
          icon: Icons.bar_chart_outlined,
          label: 'Informes',
          onTap: () => context.go('/admin/reports'),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, List<ServiceOrder> orders) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No hay órdenes registradas')),
        ),
      );
    }
    return Column(
      children: orders.map((order) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () => context.go('/admin/orders/${order.id}'),
          title: Text('Orden #${order.orderNumber}'),
          subtitle: Text(order.serviceType),
          trailing: _StatusBadge(status: order.status),
        ),
      )).toList(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        orderStatusLabels[status] ?? '...',
        style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
