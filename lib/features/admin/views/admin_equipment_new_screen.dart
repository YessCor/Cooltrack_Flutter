import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';

final clientsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ApiClient();
  try {
    final response = await api.get('/clients');
    return response['data'] as List? ?? [];
  } catch (e) {
    return [];
  }
});

class AdminEquipmentNewScreen extends ConsumerStatefulWidget {
  final String? clientId;

  const AdminEquipmentNewScreen({super.key, this.clientId});

  @override
  ConsumerState<AdminEquipmentNewScreen> createState() => _AdminEquipmentNewScreenState();
}

class _AdminEquipmentNewScreenState extends ConsumerState<AdminEquipmentNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedClientId;
  EquipmentType _selectedType = EquipmentType.split;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ApiClient();
      await api.post('/equipment', data: {
        'client_id': _selectedClientId,
        'name': _nameController.text.trim(),
        'type': equipmentTypeToString(_selectedType),
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'model': _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        'serial_number': _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
        'capacity_tons': _capacityController.text.trim().isEmpty ? null : double.tryParse(_capacityController.text.trim()),
        'location_description': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo creado')));
        context.go('/admin/equipment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Equipo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Cliente'),
              const SizedBox(height: 12),
              clientsAsync.when(
                data: (clients) => DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: _inputDecoration('Seleccionar Cliente *', Icons.person),
                  items: clients.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedClientId = v),
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Información del Equipo'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nombre del Equipo *', Icons.hvac),
                validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EquipmentType>(
                value: _selectedType,
                decoration: _inputDecoration('Tipo de Equipo', Icons.category),
                items: EquipmentType.values.map((t) => DropdownMenuItem(value: t, child: Text(equipmentTypeLabels[t] ?? 'Otro'))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _brandController, decoration: _inputDecoration('Marca', Icons.business))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _modelController, decoration: _inputDecoration('Modelo', Icons.devices))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _serialController, decoration: _inputDecoration('Número de Serie', Icons.qr_code)),
              const SizedBox(height: 16),
              TextFormField(controller: _capacityController, keyboardType: TextInputType.number, decoration: _inputDecoration('Capacidad (toneladas)', Icons.speed)),
              const SizedBox(height: 24),
              _buildSectionTitle('Ubicación'),
              const SizedBox(height: 12),
              TextFormField(controller: _locationController, maxLines: 2, decoration: _inputDecoration('Ubicación', Icons.location_on)),
              const SizedBox(height: 24),
              _buildSectionTitle('Notas'),
              const SizedBox(height: 12),
              TextFormField(controller: _notesController, maxLines: 3, decoration: _inputDecoration('Notas', Icons.notes)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEquipment,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Crear Equipo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

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