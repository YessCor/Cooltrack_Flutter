import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../models/quote.dart';

final clientsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ApiClient();
  try {
    final response = await api.get('/clients');
    return response['data'] as List? ?? [];
  } catch (e) {
    return [];
  }
});

final ordersListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ApiClient();
  try {
    final response = await api.get('/orders');
    return response['data'] as List? ?? [];
  } catch (e) {
    return [];
  }
});

class AdminQuoteNewScreen extends ConsumerStatefulWidget {
  const AdminQuoteNewScreen({super.key});

  @override
  ConsumerState<AdminQuoteNewScreen> createState() => _AdminQuoteNewScreenState();
}

class _AdminQuoteNewScreenState extends ConsumerState<AdminQuoteNewScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  String? _selectedOrderId;
  final _items = <_QuoteItemData>[];
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_QuoteItemData());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + (item.quantity * item.price));
  double get _tax => _subtotal * 0.16;
  double get _total => _subtotal + _tax;

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ApiClient();
      await api.post('/quotes', data: {
        'client_id': _selectedClientId,
        'order_id': _selectedOrderId,
        'items': _items.where((i) => i.description.isNotEmpty).map((i) => ({
          'description': i.description,
          'quantity': i.quantity,
          'unit_price': i.price,
        })).toList(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización creada')));
        context.go('/admin/quotes');
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
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización'),
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
                  decoration: _inputDecoration('Seleccionar Cliente', Icons.person),
                  items: clients.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedClientId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Orden (Opcional)'),
              const SizedBox(height: 12),
              ordersAsync.when(
                data: (orders) => DropdownButtonFormField<String?>(
                  value: _selectedOrderId,
                  decoration: _inputDecoration('Seleccionar Orden', Icons.assignment),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin orden')),
                    ...orders.map((o) => DropdownMenuItem(value: o['id'] as String, child: Text(o['order_number'] as String))),
                  ],
                  onChanged: (v) => setState(() => _selectedOrderId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error'),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Items'),
              const SizedBox(height: 12),
              ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Item'),
              ),
              const SizedBox(height: 16),
              _buildTotals(),
              const SizedBox(height: 24),
              _buildSectionTitle('Notas'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration('Notas adicionales', Icons.notes),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Crear Cotización'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _buildItemRow(int index, _QuoteItemData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: TextFormField(controller: item.descController, decoration: _inputDecoration('Descripción', Icons.description))),
                if (_items.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(index)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: item.qtyController, keyboardType: TextInputType.number, decoration: _inputDecoration('Cantidad', Icons.numbers), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: item.priceController, keyboardType: TextInputType.number, decoration: _inputDecoration('Precio', Icons.attach_money), onChanged: (_) => setState(() {}))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Subtotal', _subtotal),
            const SizedBox(height: 8),
            _totalRow('IVA (16%)', _tax),
            const Divider(height: 24),
            _totalRow('Total', _total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: isBold ? AppColors.secondary : null)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.textMuted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
  }
}

class _QuoteItemData {
  final TextEditingController descController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController(text: '0');

  String get description => descController.text.trim();
  int get quantity => int.tryParse(qtyController.text) ?? 1;
  double get price => double.tryParse(priceController.text) ?? 0;

  void dispose() {
    descController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}