import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/equipment.dart';

final equipmentDetailProvider = FutureProvider.family<Equipment?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/equipment/$id');
    return Equipment.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

class ClientEquipmentDetailScreen extends ConsumerWidget {
  final String equipmentId;

  const ClientEquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentDetailProvider(equipmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Equipo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: equipmentAsync.when(
        data: (equipment) {
          if (equipment == null) {
            return const Center(child: Text('Equipo no encontrado'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(equipment),
                const SizedBox(height: 24),
                _buildInfoSection('Información General', [
                  _InfoRow('Nombre', equipment.name),
                  _InfoRow('Tipo', equipment.typeLabel),
                  if (equipment.brand != null) _InfoRow('Marca', equipment.brand!),
                  if (equipment.model != null) _InfoRow('Modelo', equipment.model!),
                  if (equipment.serialNumber != null) _InfoRow('Número de Serie', equipment.serialNumber!),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Capacidad', [
                  if (equipment.capacityTons != null)
                    _InfoRow('Capacidad', '${equipment.capacityTons} toneladas'),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Ubicación', [
                  if (equipment.locationDescription != null)
                    _InfoRow('Ubicación', equipment.locationDescription!),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Mantenimiento', [
                  if (equipment.installationDate != null)
                    _InfoRow('Fecha de Instalación', _formatDate(equipment.installationDate!)),
                  if (equipment.lastServiceDate != null)
                    _InfoRow('Último Servicio', _formatDate(equipment.lastServiceDate!)),
                ]),
                if (equipment.notes != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Notas', [
                    _InfoRow('', equipment.notes!),
                  ]),
                ],
                const SizedBox(height: 24),
                _buildActions(context, equipment),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeader(Equipment equipment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.hvac, color: AppColors.secondary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            equipment.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            equipment.typeLabel,
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.label, style: TextStyle(color: AppColors.textMuted)),
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

  Widget _buildActions(BuildContext context, Equipment equipment) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/client/new-request'),
            icon: const Icon(Icons.build),
            label: const Text('Solicitar Servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);
}