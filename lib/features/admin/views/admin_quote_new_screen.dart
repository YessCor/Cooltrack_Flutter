import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../providers/admin_provider.dart';
import '../../../models/service_catalog.dart';
import '../../../models/user.dart';
import '../../../models/service_order.dart';

class AdminQuoteNewScreen extends ConsumerStatefulWidget {
  const AdminQuoteNewScreen({super.key});

  @override
  ConsumerState<AdminQuoteNewScreen> createState() => _AdminQuoteNewScreenState();
}

class _AdminQuoteNewScreenState extends ConsumerState<AdminQuoteNewScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  String? _selectedOrderId;
  final List<_QuoteItemRowData> _items = [];
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
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_QuoteItemRowData());
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

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * 0.16;
  double get _total => _subtotal + _tax;

  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
      return;
    }

    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      // 1. Crear la cabecera de la cotización
      final quoteResponse = await supabase.from('quotes').insert({
        'client_id': _selectedClientId,
        'order_id': _selectedOrderId,
        'status': 'sent',
        'subtotal': _subtotal,
        'tax_rate': 16.0,
        'tax_amount': _tax,
        'total': _total,
        'notes': _notesController.text.trim(),
        'valid_until': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      }).select().single();

      final String quoteId = quoteResponse['id'];

      // 2. Crear los items
      final List<Map<String, dynamic>> itemsData = _items.map((item) => {
        'quote_id': quoteId,
        'catalog_item_id': item.catalogItemId,
        'description': item.descController.text,
        'quantity': double.tryParse(item.qtyController.text) ?? 1.0,
        'unit_price': double.tryParse(item.priceController.text) ?? 0.0,
        'total': item.total,
      }).toList();

      await supabase.from('quote_items').insert(itemsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización creada y enviada'), backgroundColor: AppColors.success)
        );
        context.go('/admin/quotes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);
    final catalogAsync = ref.watch(serviceCatalogProvider);
    final ordersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: 'Información General',
                child: Column(
                  children: [
                    clientsAsync.when(
                      data: (clients) => DropdownButtonFormField<String>(
                        value: _selectedClientId,
                        decoration: const InputDecoration(labelText: 'Cliente', prefixIcon: Icon(Icons.person_outline)),
                        items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedClientId = val),
                        validator: (val) => val == null ? 'Seleccione un cliente' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error al cargar clientes'),
                    ),
                    const SizedBox(height: 16),
                    ordersAsync.when(
                      data: (orders) => DropdownButtonFormField<String?>(
                        value: _selectedOrderId,
                        decoration: const InputDecoration(labelText: 'Vincular a Orden (Opcional)', prefixIcon: Icon(Icons.assignment_outlined)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Ninguna')),
                          ...orders.map((o) => DropdownMenuItem(value: o.id, child: Text('Orden #${o.orderNumber}'))),
                        ],
                        onChanged: (val) => setState(() => _selectedOrderId = val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error al cargar órdenes'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Items de la Cotización', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              catalogAsync.when(
                data: (catalog) => Column(
                  children: [
                    ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value, catalog)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar otro item'),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              _buildTotalsCard(),
              const SizedBox(height: 24),
              const Text('Notas / Términos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Ej: Válido por 15 días. Incluye materiales.'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _createQuote,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Generar Cotización', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, _QuoteItemRowData item, List<ServiceCatalog> catalog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: item.catalogItemId,
                    decoration: const InputDecoration(labelText: 'Servicio del Catálogo'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Manual / Otro')),
                      ...catalog.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        item.catalogItemId = val;
                        if (val != null) {
                          final catalogItem = catalog.firstWhere((element) => element.id == val);
                          item.descController.text = catalogItem.name;
                          item.priceController.text = catalogItem.basePrice.toString();
                        }
                      });
                    },
                  ),
                ),
                if (_items.length > 1)
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => _removeItem(index)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.descController,
              decoration: const InputDecoration(labelText: 'Descripción personalizada'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cant.'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio Unit.', prefixText: '\$'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Item', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _rowTotal('Subtotal', _subtotal),
            const SizedBox(height: 4),
            _rowTotal('IVA (16%)', _tax),
            const Divider(),
            _rowTotal('TOTAL', _total, isBold: true, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _rowTotal(String label, double val, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text('\$${val.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: isBold ? 18 : 14)),
      ],
    );
  }
}

class _QuoteItemRowData {
  String? catalogItemId;
  final descController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController(text: '0');

  double get total {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    descController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}
