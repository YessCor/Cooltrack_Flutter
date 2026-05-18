import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';
import '../providers/tech_jobs_provider.dart';

class TechJobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const TechJobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<TechJobDetailScreen> createState() => _TechJobDetailScreenState();
}

class _TechJobDetailScreenState extends ConsumerState<TechJobDetailScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Trabajo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/technician'),
        ),
      ),
      body: jobAsync.when(
        data: (job) => _buildContent(context, job),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic job) {
    final nextStatus = technicianNextStatus[job.status];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(job),
          const SizedBox(height: 24),
          _buildInfoSection(job),
          const SizedBox(height: 24),
          _buildDescriptionSection(job),
          const SizedBox(height: 24),
          _buildTimelineSection(job),
          const SizedBox(height: 24),
          _buildNotesSection(job),
          if (job.status == OrderStatus.inProgress) ...[
            const SizedBox(height: 24),
            _buildPartsSection(),
          ],
          const SizedBox(height: 32),
          if (nextStatus != null) _buildActionButton(job, nextStatus),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden ${job.orderNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.work, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  job.serviceType,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.address,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Prioridad', value: job.priority),
            if (job.scheduledDate != null)
              _InfoRow(
                label: 'Fecha Programada',
                value: _formatDate(job.scheduledDate!),
              ),
            if (job.totalAmount != null)
              _InfoRow(
                label: 'Monto Total',
                value: '\$${job.totalAmount!.toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description.isEmpty ? 'Sin descripción' : job.description,
              style: TextStyle(
                color: job.description.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Línea de Tiempo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _TimelineItem(
              label: 'Creado',
              time: job.createdAt,
              isActive: true,
            ),
            if (job.startedAt != null)
              _TimelineItem(
                label: 'Iniciado',
                time: job.startedAt,
                isActive: true,
              ),
            if (job.completedAt != null)
              _TimelineItem(
                label: 'Completado',
                time: job.completedAt,
                isActive: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(dynamic job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas del Técnico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Agregar notas sobre el trabajo...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Refacciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega las refacciones utilizadas en este trabajo',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(dynamic job, OrderStatus nextStatus) {
    final buttonText = _getButtonText(nextStatus);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _updateStatus(job, nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                buttonText,
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  String _getButtonText(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Iniciar Camino';
      case OrderStatus.inTransit:
        return 'Llegué al Lugar';
      case OrderStatus.inProgress:
        return 'Completar Trabajo';
      default:
        return 'Actualizar Estado';
    }
  }

  Future<void> _updateStatus(dynamic job, OrderStatus nextStatus) async {
    setState(() => _isLoading = true);

    try {
      final updateFn = ref.read(updateJobStatusProvider);
      await updateFn(JobUpdateRequest(
        orderId: job.id,
        newStatus: nextStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${orderStatusLabels[nextStatus]}'),
            backgroundColor: AppColors.success,
          ),
        );

        if (nextStatus == OrderStatus.completed) {
          context.go('/technician');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        orderStatusLabels[status] ?? 'Desconocido',
        style: TextStyle(
          fontSize: 14,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isActive;

  const _TimelineItem({
    required this.label,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.success : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatDate(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}