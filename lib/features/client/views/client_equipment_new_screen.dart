import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../providers/auth_provider.dart';

class ClientEquipmentNewScreen extends ConsumerStatefulWidget {
  const ClientEquipmentNewScreen({super.key});

  @override
  ConsumerState<ClientEquipmentNewScreen> createState() => _ClientEquipmentNewScreenState();
}

class _ClientEquipmentNewScreenState extends ConsumerState<ClientEquipmentNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  EquipmentType _selectedType = EquipmentType.split;
  bool _isLoading = false;

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

    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) {
      _showError('Usuario no identificado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiClient();
      await api.post('/equipment', data: {
        'client_id': userId,
        'name': _nameController.text.trim(),
        'type': equipmentTypeToString(_selectedType),
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'model': _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        'serial_number': _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
        'capacity_tons': _capacityController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_capacityController.text.trim()),
        'location_description': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipo guardado exitosamente')),
        );
        context.go('/client/equipment');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar el equipo');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Equipo'),
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
              _buildSectionTitle('Información del Equipo'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nombre del Equipo *', Icons.hvac),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EquipmentType>(
                value: _selectedType,
                decoration: _inputDecoration('Tipo de Equipo', Icons.category),
                items: EquipmentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(equipmentTypeLabels[type] ?? 'Otro'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: _inputDecoration('Marca', Icons.business),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: _inputDecoration('Modelo', Icons.devices),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialController,
                decoration: _inputDecoration('Número de Serie', Icons.qr_code),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: _inputDecoration('Capacidad (toneladas)', Icons.speed),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Ubicación'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Ubicación (ej: Sala principal)', Icons.location_on),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Notas Adicionales'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Notas', Icons.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEquipment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Guardar Equipo', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    );
  }
}