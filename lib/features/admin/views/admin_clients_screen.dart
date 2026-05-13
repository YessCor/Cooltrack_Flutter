import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/client.dart';

final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/clients');
  final List<dynamic> data = response['data'];
  return data.map((e) => Client.fromJson(e)).toList();
});

class AdminClientsScreen extends ConsumerWidget {
  const AdminClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search
            },
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) => clients.isEmpty
            ? _buildEmptyState(context)
            : _buildClientList(context, clients),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
              ElevatedButton(
                onPressed: () => ref.refresh(clientsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No hay clientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/admin/clients/new'),
            child: const Text('Agregar Cliente'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList(BuildContext context, List<Client> clients) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(clientsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: clients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final client = clients[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.2),
                child: Text(
                  client.name[0].toUpperCase(),
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
              title: Text(client.name),
              subtitle: Text(client.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!client.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inactivo',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => context.go('/admin/clients/${client.id}'),
            ),
          );
        },
      ),
    );
  }
}