import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/quote.dart';

final techQuoteDetailProvider = FutureProvider.family<Quote?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/quotes/$id');
    return Quote.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

class TechQuoteDetailScreen extends ConsumerStatefulWidget {
  final String quoteId;

  const TechQuoteDetailScreen({super.key, required this.quoteId});

  @override
  ConsumerState<TechQuoteDetailScreen> createState() => _TechQuoteDetailScreenState();
}

class _TechQuoteDetailScreenState extends ConsumerState<TechQuoteDetailScreen> {
  final _items = <_QuoteItemData>[];
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  void _loadQuote() {
    ref.read(techQuoteDetailProvider(widget.quoteId).future).then((quote) {
      if (quote != null && quote.status == QuoteStatus.draft) {
        setState(() {
          _items.clear();
          for (final item in quote.items) {
            _items.add(_QuoteItemData(
              descController: TextEditingController(text: item.description),
              qtyController: TextEditingController(text: item.quantity.toString()),
              priceController: TextEditingController(text: item.unitPrice.toString()),
            ));
          }
          if (_items.isEmpty) _addItem();
        });
      }
    });
  }

  @override
  void dispose() {
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
    setState(() => _isSaving = true);
    try {
      final api = ApiClient();
      await api.put('/quotes/${widget.quoteId}', data: {
        'items': _items.where((i) => i.description.isNotEmpty).map((i) => ({
          'description': i.description,
          'quantity': i.quantity,
          'unit_price': i.price,
        })).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización guardada')));
        ref.invalidate(techQuoteDetailProvider(widget.quoteId));
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
    final quoteAsync = ref.watch(techQuoteDetailProvider(widget.quoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
        ],
      ),
      body: quoteAsync.when(
        data: (quote) {
          if (quote == null) return const Center(child: Text('Cotización no encontrada'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(quote),
                const SizedBox(height: 24),
                _buildInfoSection(quote),
                const SizedBox(height: 24),
                if (_isEditing) _buildItemsEditor() else _buildItemsView(quote),
                const SizedBox(height: 16),
                _buildTotals(quote),
                const SizedBox(height: 24),
                if (quote.status == QuoteStatus.draft && !_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                      child: const Text('Editar Cotización'),
                    ),
                  ),
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveQuote,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(Quote quote) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(quote.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(quote.status), color: _getStatusColor(quote.status), size: 48),
          const SizedBox(height: 12),
          Text(quote.quoteNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(quote.statusLabel, style: TextStyle(color: _getStatusColor(quote.status))),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Quote quote) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Fecha', _formatDate(quote.createdAt)),
            if (quote.validUntil != null) _infoRow('Válida hasta', _formatDate(quote.validUntil!)),
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

  Widget _buildItemsView(Quote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quote.items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final item = quote.items[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Text('x${item.quantity}', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 16),
                    Text('\$${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Agregar Item')),
      ],
    );
  }

  Widget _buildItemRow(int index, _QuoteItemData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: item.descController, decoration: const InputDecoration(hintText: 'Descripción'), onChanged: (_) => setState(() {}))),
                if (_items.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeItem(index)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: item.qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Cant'), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: item.priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Precio'), onChanged: (_) => setState(() {}))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals(Quote quote) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Subtotal', '\$${(_isEditing ? _subtotal : quote.subtotal).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _infoRow('IVA (16%)', '\$${(_isEditing ? _tax : quote.tax).toStringAsFixed(2)}'),
            const Divider(height: 24),
            _infoRow('Total', '\$${(_isEditing ? _total : quote.total).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft: return Colors.grey;
      case QuoteStatus.sent: return Colors.blue;
      case QuoteStatus.approved: return Colors.green;
      case QuoteStatus.rejected: return Colors.red;
      case QuoteStatus.expired: return Colors.orange;
    }
  }

  IconData _getStatusIcon(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft: return Icons.edit;
      case QuoteStatus.sent: return Icons.send;
      case QuoteStatus.approved: return Icons.check_circle;
      case QuoteStatus.rejected: return Icons.cancel;
      case QuoteStatus.expired: return Icons.timer_off;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _QuoteItemData {
  final TextEditingController descController;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _QuoteItemData({TextEditingController? descController, TextEditingController? qtyController, TextEditingController? priceController})
      : descController = descController ?? TextEditingController(),
        qtyController = qtyController ?? TextEditingController(text: '1'),
        priceController = priceController ?? TextEditingController(text: '0');

  String get description => descController.text.trim();
  int get quantity => int.tryParse(qtyController.text) ?? 1;
  double get price => double.tryParse(priceController.text) ?? 0;

  void dispose() {
    descController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}