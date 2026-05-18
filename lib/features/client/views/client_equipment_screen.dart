import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/client_provider.dart';
import '../../../models/equipment.dart';

class ClientEquipmentScreen extends ConsumerWidget {
  const ClientEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(clientEquipmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Equipos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/client/equipment/new'),
          ),
        ],
      ),
      body: equipmentAsync.when(
        data: (equipmentList) {
          if (equipmentList.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(clientEquipmentProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: equipmentList.length,
              itemBuilder: (context, index) {
                final equipment = equipmentList[index];
                return _EquipmentCard(equipment: equipment);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hvac_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No tienes equipos registrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra tus aires acondicionados para solicitar mantenimiento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/client/equipment/new'),
            child: const Text('Registrar mi primer equipo'),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;

  const _EquipmentCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/client/equipment/${equipment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.ac_unit, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${equipment.brand ?? "Sin marca"} - ${equipment.model ?? "Sin modelo"}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tipo: ${equipment.typeLabel}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
