import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/equipment.dart';

final equipmentProvider = FutureProvider<List<Equipment>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/equipment');
  final List<dynamic> data = response['data'];
  return data.map((e) => Equipment.fromJson(e)).toList();
});

class AdminEquipmentScreen extends ConsumerWidget {
  const AdminEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipAsync = ref.watch(equipmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Equipos')),
      body: equipAsync.when(
        data: (equip) => equip.isEmpty
            ? const Center(child: Text('No hay equipos'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: equip.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = equip[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        child: const Icon(Icons.hvac, color: AppColors.secondary),
                      ),
                      title: Text(item.name),
                      subtitle: Text('${item.typeLabel} - ${item.brand ?? "Sin marca"}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/admin/equipment/${item.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/equipment/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}