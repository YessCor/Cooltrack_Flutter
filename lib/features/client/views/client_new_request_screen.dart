import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/equipment.dart';

final clientEquipmentForRequestProvider = FutureProvider<List<Equipment>>((ref) async {
  final api = ApiClient();
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  
  if (userId == null) return [];
  
  try {
    final response = await api.get('/equipment', queryParams: {'client_id': userId});
    final data = response['data'] as List? ?? [];
    return data.map((json) => Equipment.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

class ClientNewRequestScreen extends ConsumerStatefulWidget {
  const ClientNewRequestScreen({super.key});

  @override
  ConsumerState<ClientNewRequestScreen> createState() => _ClientNewRequestScreenState();
}

class _ClientNewRequestScreenState extends ConsumerState<ClientNewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedServiceType = 'maintenance';
  String _selectedPriority = 'normal';
  String? _selectedEquipmentId;
  DateTime? _scheduledDate;
  bool _isLoading = false;

  final List<Map<String, String>> _serviceTypes = [
    {'value': 'maintenance', 'label': 'Mantenimiento'},
    {'value': 'repair', 'label': 'Reparación'},
    {'value': 'installation', 'label': 'Instalación'},
    {'value': 'inspection', 'label': 'Inspección'},
    {'value': 'other', 'label': 'Otro'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Baja'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'high', 'label': 'Alta'},
    {'value': 'urgent', 'label': 'Urgente'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _submitRequest() async {
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
      await api.post('/orders', data: {
        'client_id': userId,
        'service_type': _selectedServiceType,
        'priority': _selectedPriority,
        'description': _descriptionController.text.trim(),
        'equipment_id': _selectedEquipmentId,
        'address': _addressController.text.trim(),
        'scheduled_date': _scheduledDate?.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada exitosamente')),
        );
        context.go('/client');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al enviar la solicitud');
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
    final equipmentAsync = ref.watch(clientEquipmentForRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Solicitud'),
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
              _buildSectionTitle('Tipo de Servicio'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: _inputDecoration('Tipo de Servicio', Icons.build),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedServiceType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: _inputDecoration('Prioridad', Icons.priority_high),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority['value'],
                    child: Text(priority['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Detalles'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Descripción del Problema *', Icons.description),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describa el problema';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Dirección *', Icons.location_on),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Equipo (Opcional)'),
              const SizedBox(height: 16),
              equipmentAsync.when(
                data: (equipment) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedEquipmentId,
                    decoration: _inputDecoration('Seleccionar Equipo', Icons.hvac),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin equipo específico'),
                      ),
                      ...equipment.map((eq) {
                        return DropdownMenuItem(
                          value: eq.id,
                          child: Text(eq.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedEquipmentId = value);
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar equipos'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Fecha Programada (Opcional)'),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      Text(
                        _scheduledDate != null
                            ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _scheduledDate != null ? Colors.black : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
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
                      : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16)),
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