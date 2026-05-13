import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ApiClient();
  final response = await api.get('/dashboard/stats');
  return DashboardStats.fromJson(response['data']);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error al cargar datos: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardStatsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick actions
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardStats stats) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            _buildStatsGrid(stats),
            const SizedBox(height: 24),
            
            // Quick actions
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            
            // Recent orders
            Text(
              'Órdenes Recientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentOrders(context),
          ],
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
          title: 'Total Órdenes',
          value: stats.totalOrders.toString(),
          icon: Icons.assignment,
          color: AppColors.secondary,
        ),
        _StatCard(
          title: 'Activas',
          value: stats.activeOrders.toString(),
          icon: Icons.engineering,
          color: AppColors.warning,
        ),
        _StatCard(
          title: 'Completadas',
          value: stats.completedOrders.toString(),
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'Ingresos',
          value: stats.formattedRevenue,
          icon: Icons.attach_money,
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.person_add,
            label: 'Nuevo Cliente',
            onTap: () => context.go('/admin/clients/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.engineering,
            label: 'Nuevo Técnico',
            onTap: () => context.go('/admin/technicians'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long,
            label: 'Nueva Cotización',
            onTap: () => context.go('/admin/quotes/new'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(
              Icons.assignment,
              color: AppColors.secondary,
            ),
          ),
          title: Text('Orden #${1000 + index}'),
          subtitle: Text('Cliente ${index + 1} - En progreso'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/admin/orders/${1000 + index}'),
        ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}