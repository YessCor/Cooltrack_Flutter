import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/client.dart';
import '../../../models/equipment.dart';

final clientDetailProvider = FutureProvider.family<Client?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/clients/$id');
    return Client.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

final clientEquipmentListProvider = FutureProvider.family<List<Equipment>, String>((ref, clientId) async {
  final api = ApiClient();
  try {
    final response = await api.get('/equipment', queryParams: {'client_id': clientId});
    final data = response['data'] as List? ?? [];
    return data.map((json) => Equipment.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class AdminClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const AdminClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<AdminClientDetailScreen> createState() => _AdminClientDetailScreenState();
}

class _AdminClientDetailScreenState extends ConsumerState<AdminClientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  Client? _client;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  void _loadClient() {
    ref.read(clientDetailProvider(widget.clientId).future).then((client) {
      if (client != null) {
        setState(() {
          _client = client;
          _nameController.text = client.name;
          _emailController.text = client.email ?? '';
          _phoneController.text = client.phone ?? '';
          _addressController.text = client.address ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final api = ApiClient();
      await api.put('/clients/${widget.clientId}', data: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente actualizado')),
        );
        setState(() => _isEditing = false);
        ref.invalidate(clientDetailProvider(widget.clientId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));
    final equipmentAsync = ref.watch(clientEquipmentListProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cliente'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) return const Center(child: Text('Cliente no encontrado'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientHeader(client),
                const SizedBox(height: 24),
                _buildClientForm(),
                const SizedBox(height: 24),
                _buildEquipmentSection(equipmentAsync),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildClientHeader(Client client) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              client.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(client.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          if (client.email != null) Text(client.email!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildClientForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información del Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: _inputDecoration('Nombre *', Icons.person),
            validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.email),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Teléfono', Icons.phone),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            enabled: _isEditing,
            maxLines: 2,
            decoration: _inputDecoration('Dirección', Icons.location_on),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveClient,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(AsyncValue<List<Equipment>> equipmentAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Equipos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => context.go('/admin/equipment/new?client_id=${widget.clientId}'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        equipmentAsync.when(
          data: (equipment) {
            if (equipment.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('No hay equipos registrados')),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: equipment.length,
              itemBuilder: (context, index) {
                final eq = equipment[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.hvac, color: AppColors.secondary),
                    ),
                    title: Text(eq.name),
                    subtitle: Text(eq.typeLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin/equipment/${eq.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error al cargar equipos'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
    );
  }
}