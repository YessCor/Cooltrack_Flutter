import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/user.dart';

final techniciansProvider = FutureProvider<List<User>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/technicians');
  final List<dynamic> data = response['data'];
  return data.map((e) => User.fromJson(e)).toList();
});

class AdminTechniciansScreen extends ConsumerWidget {
  const AdminTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techAsync = ref.watch(techniciansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicos'),
      ),
      body: techAsync.when(
        data: (techs) => techs.isEmpty
            ? const Center(child: Text('No hay técnicos'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: techs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tech = techs[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        child: Text(tech.name[0].toUpperCase(),
                            style: TextStyle(color: AppColors.secondary)),
                      ),
                      title: Text(tech.name),
                      subtitle: Text(tech.phone ?? tech.email),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tech.isActive
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tech.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 12,
                            color: tech.isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add technician
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}