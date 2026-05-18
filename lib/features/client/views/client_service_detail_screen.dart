import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/service_order.dart';

final clientServiceDetailProvider = FutureProvider.family<ServiceOrder?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/orders/$id');
    return ServiceOrder.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

class ClientServiceDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ClientServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(clientServiceDetailProvider(serviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Servicio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return const Center(child: Text('Servicio no encontrado'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(service),
                const SizedBox(height: 24),
                _buildStatusTimeline(service),
                const SizedBox(height: 24),
                _buildInfoSection('Detalles del Servicio', [
                  _InfoRow('Número de Orden', service.orderNumber),
                  _InfoRow('Tipo de Servicio', _getServiceTypeLabel(service.serviceType)),
                  _InfoRow('Prioridad', _getPriorityLabel(service.priority)),
                  _InfoRow('Descripción', service.description),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Ubicación', [
                  _InfoRow('Dirección', service.address),
                ]),
                if (service.technicianNotes != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Notas del Técnico', [
                    _InfoRow('', service.technicianNotes!),
                  ]),
                ],
                if (service.totalAmount != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Costo', [
                    _InfoRow('Total', '\$${service.totalAmount!.toStringAsFixed(2)}'),
                  ]),
                ],
                const SizedBox(height: 24),
                if (service.status == OrderStatus.completed) _buildRatingSection(context, service),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeader(ServiceOrder service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(service.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(service.status).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(service.status), color: _getStatusColor(service.status), size: 48),
          const SizedBox(height: 12),
          Text(
            service.statusLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(service.status),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            service.orderNumber,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(ServiceOrder service) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.assigned,
      OrderStatus.accepted,
      OrderStatus.inTransit,
      OrderStatus.inProgress,
      OrderStatus.completed,
    ];

    final currentIndex = statuses.indexOf(service.status);
    final isCompleted = service.status == OrderStatus.completed;
    final isCancelled = service.status == OrderStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Servicio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.secondary : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTimelineIcon(status),
                          color: isActive ? Colors.white : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getShortStatusLabel(status),
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.secondary : AppColors.textMuted,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (index < statuses.length - 1)
                    Container(
                      width: 30,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: index < currentIndex ? AppColors.secondary : Colors.grey.shade300,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        if (isCancelled)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Este servicio fue cancelado', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.where((r) => r.value.isNotEmpty).map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.label, style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context, ServiceOrder service) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calificar Servicio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (service.clientRating != null)
              Row(
                children: List.generate(5, (index) => Icon(
                  index < service.clientRating! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                )),
              )
            else
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                child: const Text('Calificar'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.assigned:
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inTransit:
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.assigned:
        return Icons.person;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.inTransit:
        return Icons.directions_car;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  IconData _getTimelineIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.assigned:
        return Icons.person;
      case OrderStatus.accepted:
        return Icons.check;
      case OrderStatus.inTransit:
        return Icons.directions_car;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getShortStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.assigned:
        return 'Asignado';
      case OrderStatus.accepted:
        return 'Aceptado';
      case OrderStatus.inTransit:
        return 'En Camino';
      case OrderStatus.inProgress:
        return 'En Trabajo';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  String _getServiceTypeLabel(String type) {
    switch (type) {
      case 'maintenance':
        return 'Mantenimiento';
      case 'repair':
        return 'Reparación';
      case 'installation':
        return 'Instalación';
      case 'inspection':
        return 'Inspección';
      default:
        return type;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);
}