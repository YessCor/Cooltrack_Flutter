import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../providers/tech_jobs_provider.dart';
import '../../../components/signature_pad.dart';
import '../../../services/sync_service.dart';

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

  void _showSignaturePad(dynamic job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Firma del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor, pida al cliente que firme a continuación para confirmar la finalización del servicio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SignaturePad(
              onSave: (filePath) async {
                Navigator.pop(context);
                await _completeJobWithSignature(job, filePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeJobWithSignature(dynamic job, String signaturePath) async {
    setState(() => _isLoading = true);
    try {
      final syncService = SyncService();
      
      // 1. Encolar la firma
      await syncService.queueSignatureUpload(job.id, signaturePath);
      
      // 2. Actualizar estado a completado
      final updateFn = ref.read(updateJobStatusProvider);
      await updateFn(JobUpdateRequest(
        orderId: job.id,
        newStatus: OrderStatus.completed,
        notes: _notesController.text,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trabajo completado con éxito'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/technician');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          const SizedBox(height: 16),
          _buildInfoSection(job),
          const SizedBox(height: 16),
          _buildDescriptionSection(job),
          const SizedBox(height: 16),
          _buildNotesSection(job),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _StatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.serviceType, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(job.address, style: TextStyle(color: AppColors.textMuted))),
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
            _InfoRow(label: 'Prioridad', value: job.priority),
            if (job.scheduledDate != null)
              _InfoRow(label: 'Programado', value: _formatDate(job.scheduledDate!)),
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
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(job.description),
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
            const Text('Notas del Técnico', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Agregar detalles del servicio...'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(dynamic job, OrderStatus nextStatus) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading 
          ? null 
          : () {
              if (nextStatus == OrderStatus.completed) {
                _showSignaturePad(job);
              } else {
                _updateStatus(job, nextStatus);
              }
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(nextStatus == OrderStatus.completed ? 'Finalizar y Firmar' : _getButtonText(nextStatus)),
      ),
    );
  }

  String _getButtonText(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted: return 'Iniciar Camino';
      case OrderStatus.inTransit: return 'Llegué al Lugar';
      case OrderStatus.inProgress: return 'Iniciar Trabajo';
      default: return 'Siguiente Paso';
    }
  }

  Future<void> _updateStatus(dynamic job, OrderStatus nextStatus) async {
    setState(() => _isLoading = true);
    try {
      final updateFn = ref.read(updateJobStatusProvider);
      await updateFn(JobUpdateRequest(
        orderId: job.id,
        newStatus: nextStatus,
        notes: _notesController.text,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        orderStatusLabels[status] ?? 'Desconocido',
        style: const TextStyle(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.w600),
      ),
    );
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
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
