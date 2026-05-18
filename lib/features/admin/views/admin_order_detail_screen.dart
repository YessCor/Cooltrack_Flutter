import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/service_order.dart';
import '../../../models/user.dart';
import '../providers/admin_provider.dart';
import '../../../services/sync_service.dart';
import '../../../services/pdf_service.dart';
import '../../../providers/auth_provider.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  bool _isUpdating = false;
  String? _selectedTechnicianId;

  Future<void> _updateOrderStatus(OrderStatus newStatus, {String? technicianId}) async {
    setState(() => _isUpdating = true);
    try {
      final syncService = SyncService();
      final Map<String, dynamic> updateData = {
        'status': orderStatusToString(newStatus),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (technicianId != null) {
        updateData['technician_id'] = technicianId;
      }

      await syncService.queueOrderUpdate(widget.orderId, updateData);
      await syncService.queueHistoryLog(
        widget.orderId, 
        orderStatusToString(newStatus), 
        technicianId != null ? 'Técnico asignado' : 'Estado actualizado por Admin'
      );

      // Intentar sincronizar ahora
      syncService.syncAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operación exitosa'), backgroundColor: AppColors.success)
        );
        ref.invalidate(adminOrderDetailProvider(widget.orderId));
        ref.invalidate(adminDashboardStatsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showAssignDialog(List<User> technicians) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignar Técnico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  final tech = technicians[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(tech.name),
                    subtitle: Text(tech.email),
                    onTap: () {
                      Navigator.pop(context);
                      _updateOrderStatus(OrderStatus.assigned, technicianId: tech.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderDetailProvider(widget.orderId));
    final techsAsync = ref.watch(techniciansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Orden'),
        actions: [
          orderAsync.when(
            data: (order) => order != null ? IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                // En una implementación real, buscaríamos al usuario cliente por ID
                // Por ahora usamos los datos de la orden
                final client = ref.read(authProvider).user; 
                PdfService().previewOrderPdf(order, client);
              },
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (_isUpdating)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Orden no encontrada'));
          return _buildContent(context, order, techsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServiceOrder order, AsyncValue<List<User>> techsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(order),
          const SizedBox(height: 24),
          _buildAssignmentCard(order, techsAsync),
          const SizedBox(height: 24),
          _buildDetailsCard(order),
          const SizedBox(height: 24),
          if (order.status == OrderStatus.pending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Orden'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ServiceOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orden #${order.orderNumber}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(order.statusLabel, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.assignment, size: 40, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(ServiceOrder order, AsyncValue<List<User>> techsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Técnico Asignado', style: TextStyle(fontWeight: FontWeight.bold)),
                if (order.status == OrderStatus.pending || order.status == OrderStatus.assigned)
                  TextButton.icon(
                    onPressed: () => techsAsync.whenData((techs) => _showAssignDialog(techs)),
                    icon: const Icon(Icons.edit),
                    label: const Text('Cambiar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.person)),
              title: Text(order.technicianId != null ? 'Técnico ID: ${order.technicianId!.substring(0,8)}...' : 'Sin asignar'),
              subtitle: Text(order.technicianId != null ? 'Ya asignado' : 'Esta orden requiere un técnico'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ServiceOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalles del Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _DetailRow(label: 'Servicio', value: order.serviceType),
            _DetailRow(label: 'Dirección', value: order.address),
            _DetailRow(label: 'Prioridad', value: order.priority),
            _DetailRow(label: 'Creado', value: _formatDate(order.createdAt)),
            const SizedBox(height: 12),
            const Text('Descripción:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(order.description),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
