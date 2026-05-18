import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../providers/admin_provider.dart';
import '../../../models/service_catalog.dart';

class AdminServiceCatalogScreen extends ConsumerWidget {
  const AdminServiceCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(serviceCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
      ),
      body: catalogAsync.when(
        data: (items) => _buildList(context, items, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ServiceCatalog> items, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay servicios en el catálogo'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.description ?? 'Sin descripción'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(item.unit, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            onTap: () => _showEditPriceDialog(context, ref, item),
          ),
        );
      },
    );
  }

  void _showEditPriceDialog(BuildContext context, WidgetRef ref, ServiceCatalog item) {
    final controller = TextEditingController(text: item.basePrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Precio: ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Precio Base',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                await ref.read(updateServicePriceProvider)(item.id, newPrice);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    // Implementación para añadir nuevo servicio si es necesario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de añadir próximamente')),
    );
  }
}
