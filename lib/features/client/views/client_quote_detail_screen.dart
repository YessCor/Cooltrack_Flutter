import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../models/quote.dart';
import '../providers/client_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../providers/auth_provider.dart';

class ClientQuoteDetailScreen extends ConsumerStatefulWidget {
  final String quoteId;

  const ClientQuoteDetailScreen({super.key, required this.quoteId});

  @override
  ConsumerState<ClientQuoteDetailScreen> createState() => _ClientQuoteDetailScreenState();
}

class _ClientQuoteDetailScreenState extends ConsumerState<ClientQuoteDetailScreen> {
  bool _isProcessing = false;

  Future<void> _updateStatus(QuoteStatus status) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(updateQuoteStatusProvider)(widget.quoteId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == QuoteStatus.approved ? 'Cotización aprobada' : 'Cotización rechazada'),
            backgroundColor: status == QuoteStatus.approved ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(clientQuoteDetailProvider(widget.quoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        actions: [
          quoteAsync.when(
            data: (quote) => quote != null ? IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                final client = ref.read(authProvider).user;
                PdfService().previewQuotePdf(quote, client);
              },
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
                  _InfoRow('Número', 'QT-${quote.quoteNumber.toString().padLeft(4, '0')}'),
                  _InfoRow('Fecha', _formatDate(quote.createdAt)),
                  _InfoRow('Estado', quote.statusLabel),
                ]),
                if (quote.validUntil != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Validez', [
                    _InfoRow('Válida hasta', _formatDate(quote.validUntil!)),
                  ]),
                ],
                const SizedBox(height: 24),
                const Text('Items del servicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildItemsList(quote),
                const SizedBox(height: 24),
                _buildTotalsCard(quote),
                if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoSection('Notas del Técnico', [
                    _InfoRow('', quote.notes!),
                  ]),
                ],
                const SizedBox(height: 40),
                if (quote.status == QuoteStatus.sent) _buildActionButtons(),
                const SizedBox(height: 40),
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
    final color = _getStatusColor(quote.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(quote.status), color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            quote.statusLabel,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text('Código: QT-${quote.quoteNumber}', style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (row.label.isNotEmpty) Text(row.label, style: const TextStyle(color: AppColors.textMuted)),
                    Expanded(
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

  Widget _buildItemsList(Quote quote) {
    final items = quote.items ?? [];
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item.description),
            subtitle: Text('Cantidad: ${item.quantity.toStringAsFixed(0)}'),
            trailing: Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildTotalsCard(Quote quote) {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Subtotal', quote.subtotal),
            const SizedBox(height: 4),
            _totalRow('IVA (16%)', quote.taxAmount),
            const Divider(height: 24),
            _totalRow('TOTAL', quote.total, isBold: true, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
            fontSize: isBold ? 18 : 14, 
            color: color
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _updateStatus(QuoteStatus.approved),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Aprobar Cotización', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => _updateStatus(QuoteStatus.rejected),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            child: const Text('Rechazar Cotización'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.sent: return Colors.blue;
      case QuoteStatus.approved: return AppColors.success;
      case QuoteStatus.rejected: return AppColors.error;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.approved: return Icons.check_circle;
      case QuoteStatus.rejected: return Icons.cancel;
      case QuoteStatus.sent: return Icons.mark_as_unread;
      default: return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
