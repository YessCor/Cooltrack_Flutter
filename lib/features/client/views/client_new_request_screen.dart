import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/client_provider.dart';

class ClientNewRequestScreen extends ConsumerStatefulWidget {
  const ClientNewRequestScreen({super.key});

  @override
  ConsumerState<ClientNewRequestScreen> createState() => _ClientNewRequestScreenState();
}

class _ClientNewRequestScreenState extends ConsumerState<ClientNewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEquipmentId;
  String _serviceType = 'Mantenimiento Preventivo';
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  final List<String> _serviceTypes = [
    'Mantenimiento Preventivo',
    'Reparación / Correctivo',
    'Instalación',
    'Revisión Técnica',
    'Limpieza profunda',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedEquipmentId == null) {
      if (_selectedEquipmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un equipo')),
        );
      }
      return;
    }

    final success = await ref.read(newRequestProvider.notifier).createRequest(
      equipmentId: _selectedEquipmentId!,
      serviceType: _serviceType,
      description: _descriptionController.text,
      address: _addressController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada con éxito'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(clientEquipmentProvider);
    final requestState = ref.watch(newRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completa los detalles para tu solicitud de servicio técnico.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Selección de Equipo
              const Text('¿Para qué equipo es el servicio?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              equipmentAsync.when(
                data: (list) => DropdownButtonFormField<String>(
                  value: _selectedEquipmentId,
                  decoration: const InputDecoration(hintText: 'Selecciona un equipo'),
                  items: list.map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedEquipmentId = val),
                  validator: (val) => val == null ? 'Campo requerido' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar equipos'),
              ),
              const SizedBox(height: 20),

              // Tipo de Servicio
              const Text('Tipo de servicio', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(),
                items: _serviceTypes.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                )).toList(),
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
              const SizedBox(height: 20),

              // Dirección
              const Text('Dirección del servicio', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Calle 123 #45-67, Edificio X, Apto Y',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Descripción
              const Text('Descripción del problema', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe brevemente qué sucede con tu equipo...',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),

              // Botón de Envío
              ElevatedButton(
                onPressed: requestState.isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: requestState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
