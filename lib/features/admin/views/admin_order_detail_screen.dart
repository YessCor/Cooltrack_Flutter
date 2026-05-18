import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/service_order.dart';
import '../../../models/user.dart';

final orderDetailProvider = FutureProvider.family<ServiceOrder?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/orders/$id');
    return ServiceOrder.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

final techniciansListProvider = FutureProvider<List<User>>((ref) async {
  final api = ApiClient();
  try {
    final response = await api.get('/users', queryParams: {'role': 'technician'});
    final data = response['data'] as List? ?? [];
    return data.map((json) => User.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  bool _isUpdatingStatus = false;
  String? _selectedTechnicianId;
  bool _isAssigning = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final api = ApiClient();
      await api.patch('/orders/${widget.orderId}', data: {'status': orderStatusToString(newStatus)});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
        ref.invalidate(orderDetailProvider(widget.orderId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _assignTechnician() async {
    if (_selectedTechnicianId == null) return;
    setState(() => _isAssigning = true);
    try {
      final api = ApiClient();
      await api.patch('/orders/${widget.orderId}', data: {'technician_id': _selectedTechnicianId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Técnico asignado')));
        ref.invalidate(orderDetailProvider(widget.orderId));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  void _showAssignTechnicianDialog(List<User> technicians) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignar Técnico'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Seleccionar técnico'),
          items: technicians.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
          onChanged: (v) => setState(() => _selectedTechnicianId = v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: _isAssigning ? null : _assignTechnician,
            child: _isAssigning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final techniciansAsync = ref.watch(techniciansListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Orden'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Orden no encontrada'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(order),
                const SizedBox(height: 24),
                _buildStatusSection(order),
                const SizedBox(height: 24),
                _buildInfoSection('Detalles', [
                  _InfoRow('Número', order.orderNumber),
                  _InfoRow('Tipo de Servicio', _getServiceTypeLabel(order.serviceType)),
                  _InfoRow('Prioridad', _getPriorityLabel(order.priority)),
                  _InfoRow('Descripción', order.description),
                  _InfoRow('Dirección', order.address),
                ]),
                const SizedBox(height: 16),
                _buildTechnicianSection(order, techniciansAsync),
                if (order.totalAmount != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Costo', [_InfoRow('Total', '\$${order.totalAmount!.toStringAsFixed(2)}')]),
                ],
                if (order.completedAt != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Fechas', [
                    _InfoRow('Creada', _formatDate(order.createdAt)),
                    _InfoRow('Completada', _formatDate(order.completedAt!)),
                  ]),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(ServiceOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(order.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 48),
          const SizedBox(height: 12),
          Text(order.statusLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
          const SizedBox(height: 4),
          Text(order.orderNumber, style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ServiceOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cambiar Estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.status == OrderStatus.pending)
              _StatusChip(label: 'Asignar', color: Colors.blue, onTap: () => _updateStatus(OrderStatus.assigned)),
            if (order.status == OrderStatus.assigned || order.status == OrderStatus.accepted || order.status == OrderStatus.inTransit)
              _StatusChip(label: 'Cancelar', color: Colors.red, onTap: () => _updateStatus(OrderStatus.cancelled)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.where((r) => r.value.isNotEmpty).map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(r.label, style: TextStyle(color: AppColors.textMuted)), Flexible(child: Text(r.value, textAlign: TextAlign.end))],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSection(ServiceOrder order, AsyncValue<List<User>> techniciansAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Técnico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
              TextButton.icon(
                onPressed: () => techniciansAsync.whenData((techs) => _showAssignTechnicianDialog(techs))),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Asignar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppColors.secondary),
            ),
            title: Text(order.technicianId ?? 'Sin asignar'),
            subtitle: order.technicianId != null ? const Text('Técnico asignado') : const Text('No asignado'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.assigned: return Colors.blue;
      case OrderStatus.accepted: return Colors.cyan;
      case OrderStatus.inTransit: return Colors.purple;
      case OrderStatus.inProgress: return Colors.indigo;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.hourglass_empty;
      case OrderStatus.assigned: return Icons.person;
      case OrderStatus.accepted: return Icons.check_circle_outline;
      case OrderStatus.inTransit: return Icons.directions_car;
      case OrderStatus.inProgress: return Icons.build;
      case OrderStatus.completed: return Icons.check_circle;
      case OrderStatus.cancelled: return Icons.cancel;
    }
  }

  String _getServiceTypeLabel(String type) {
    switch (type) {
      case 'maintenance': return 'Mantenimiento';
      case 'repair': return 'Reparación';
      case 'installation': return 'Instalación';
      case 'inspection': return 'Inspección';
      default: return type;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low': return 'Baja';
      case 'normal': return 'Normal';
      case 'high': return 'Alta';
      case 'urgent': return 'Urgente';
      default: return priority;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      onPressed: onTap,
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}