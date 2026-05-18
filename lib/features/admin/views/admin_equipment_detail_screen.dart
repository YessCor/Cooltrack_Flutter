import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
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

class AdminEquipmentDetailScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const AdminEquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<AdminEquipmentDetailScreen> createState() => _AdminEquipmentDetailScreenState();
}

class _AdminEquipmentDetailScreenState extends ConsumerState<AdminEquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  EquipmentType _selectedType = EquipmentType.split;
  bool _isEditing = false;
  bool _isSaving = false;
  Equipment? _equipment;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  void _loadEquipment() {
    ref.read(equipmentDetailProvider(widget.equipmentId).future).then((equipment) {
      if (equipment != null) {
        setState(() {
          _equipment = equipment;
          _nameController.text = equipment.name;
          _brandController.text = equipment.brand ?? '';
          _modelController.text = equipment.model ?? '';
          _serialController.text = equipment.serialNumber ?? '';
          _capacityController.text = equipment.capacityTons?.toString() ?? '';
          _locationController.text = equipment.locationDescription ?? '';
          _notesController.text = equipment.notes ?? '';
          _selectedType = equipment.type;
        });
      }
    });
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

    setState(() => _isSaving = true);

    try {
      final api = ApiClient();
      await api.put('/equipment/${widget.equipmentId}', data: {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo actualizado')));
        setState(() => _isEditing = false);
        ref.invalidate(equipmentDetailProvider(widget.equipmentId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEquipment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Equipo'),
        content: const Text('¿Está seguro de eliminar este equipo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ApiClient();
        await api.delete('/equipment/${widget.equipmentId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo eliminado')));
          context.go('/admin/equipment');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentDetailProvider(widget.equipmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Equipo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true)),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (value) {
              if (value == 'delete') _deleteEquipment();
            },
          ),
        ],
      ),
      body: equipmentAsync.when(
        data: (equipment) {
          if (equipment == null) return const Center(child: Text('Equipo no encontrado'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(equipment),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Información del Equipo'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: _inputDecoration('Nombre *', Icons.hvac),
                    validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<EquipmentType>(
                    value: _selectedType,
                    enabled: _isEditing,
                    decoration: _inputDecoration('Tipo', Icons.category),
                    items: EquipmentType.values.map((t) => DropdownMenuItem(value: t, child: Text(equipmentTypeLabels[t] ?? 'Otro'))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _brandController, enabled: _isEditing, decoration: _inputDecoration('Marca', Icons.business))),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _modelController, enabled: _isEditing, decoration: _inputDecoration('Modelo', Icons.devices))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: _serialController, enabled: _isEditing, decoration: _inputDecoration('Número de Serie', Icons.qr_code)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _capacityController, enabled: _isEditing, keyboardType: TextInputType.number, decoration: _inputDecoration('Capacidad (toneladas)', Icons.speed)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ubicación'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _locationController, enabled: _isEditing, maxLines: 2, decoration: _inputDecoration('Ubicación', Icons.location_on)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Notas'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _notesController, enabled: _isEditing, maxLines: 3, decoration: _inputDecoration('Notas', Icons.notes)),
                  const SizedBox(height: 24),
                  _buildMaintenanceInfo(equipment),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveEquipment,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(Equipment equipment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.hvac, color: AppColors.secondary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(equipment.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(equipment.typeLabel, style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMaintenanceInfo(Equipment equipment) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información de Mantenimiento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (equipment.installationDate != null)
              _infoRow('Fecha de Instalación', _formatDate(equipment.installationDate!)),
            if (equipment.lastServiceDate != null)
              _infoRow('Último Servicio', _formatDate(equipment.lastServiceDate!)),
            if (equipment.installationDate == null && equipment.lastServiceDate == null)
              const Text('Sin información de mantenimiento'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: AppColors.textMuted)), Text(value)]),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: AppColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}