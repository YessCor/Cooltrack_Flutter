import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/quote.dart';

final clientQuoteDetailProvider = FutureProvider.family<Quote?, String>((ref, id) async {
  final api = ApiClient();
  try {
    final response = await api.get('/quotes/$id');
    return Quote.fromJson(response['data']);
  } catch (e) {
    return null;
  }
});

class ClientQuoteDetailScreen extends ConsumerWidget {
  final String quoteId;

  const ClientQuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(clientQuoteDetailProvider(quoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: quoteAsync.when(
        data: (quote) {
          if (quote == null) {
            return const Center(child: Text('Cotización no encontrada'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(quote),
                const SizedBox(height: 24),
                _buildInfoSection('Información', [
                  _InfoRow('Número', quote.quoteNumber),
                  _InfoRow('Fecha', _formatDate(quote.createdAt)),
                  _InfoRow('Estado', quote.statusLabel),
                ]),
                if (quote.validUntil != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Validez', [
                    _InfoRow('Válida hasta', _formatDate(quote.validUntil!)),
                  ]),
                ],
                const SizedBox(height: 16),
                _buildItemsSection(quote),
                const SizedBox(height: 16),
                _buildTotalsSection(quote),
                if (quote.notes != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Notas', [
                    _InfoRow('', quote.notes!),
                  ]),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(context, quote),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
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
        border: Border.all(color: _getStatusColor(quote.status).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(quote.status), color: _getStatusColor(quote.status), size: 48),
          const SizedBox(height: 12),
          Text(
            quote.statusLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(quote.status),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote.quoteNumber,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.where((r) => r.value.isNotEmpty).map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.label, style: TextStyle(color: AppColors.textMuted)),
                    Flexible(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(Quote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (item.quantity > 1)
                            Text('Cantidad: ${item.quantity}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection(Quote quote) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${quote.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA (16%)'),
                Text('\$${quote.tax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '\$${quote.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Quote quote) {
    if (quote.status == QuoteStatus.sent) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Rechazar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Aprobar'),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return Colors.grey;
      case QuoteStatus.sent:
        return Colors.blue;
      case QuoteStatus.approved:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.expired:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return Icons.edit;
      case QuoteStatus.sent:
        return Icons.send;
      case QuoteStatus.approved:
        return Icons.check_circle;
      case QuoteStatus.rejected:
        return Icons.cancel;
      case QuoteStatus.expired:
        return Icons.timer_off;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);
}