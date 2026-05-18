import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../providers/client_provider.dart';
import '../../../components/sync_indicator.dart';

import '../providers/client_provider.dart';
import '../../../components/sync_indicator.dart';
import '../../../providers/notification_provider.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(clientOrdersProvider);
    final quotesAsync = ref.watch(clientQuotesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hola 👋'),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientOrdersProvider);
          ref.invalidate(clientQuotesProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              
              // Sección de Cotizaciones Pendientes
              quotesAsync.when(
                data: (quotes) {
                  final pendingQuotes = quotes.where((q) => q.status == QuoteStatus.sent).toList();
                  if (pendingQuotes.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cotizaciones por Aprobar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 12),
                      ...pendingQuotes.map((quote) => _QuoteListItem(quote: quote)),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Text(
                'Mis Servicios Recientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return _buildNoOrders(context);
                  }
                  return Column(
                    children: orders.take(5).map((order) => _OrderListItem(order: order)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Necesitas mantenimiento?',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Solicita un técnico experto para tus equipos de climatización.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/client/new-request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Solicitar Servicio Ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoOrders(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('No hay servicios activos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tus solicitudes aparecerán aquí', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final dynamic order;

  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go('/client/service/${order.id}'),
        title: Text('Orden #${order.orderNumber}'),
        subtitle: Text(order.serviceType),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            orderStatusLabels[order.status] ?? 'Desconocido',
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return AppColors.statusPending;
      case OrderStatus.inProgress: return AppColors.statusInProgress;
      case OrderStatus.completed: return AppColors.statusCompleted;
      default: return AppColors.secondary;
    }
  }
}

class _QuoteListItem extends StatelessWidget {
  final dynamic quote;

  const _QuoteListItem({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.secondary.withOpacity(0.05),
      child: ListTile(
        onTap: () => context.go('/client/quote/${quote.id}'),
        leading: const Icon(Icons.receipt_long, color: AppColors.secondary),
        title: Text('Cotización QT-${quote.quoteNumber}'),
        subtitle: Text('Total: \$${quote.total.toStringAsFixed(2)}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
      ),
    );
  }
}
