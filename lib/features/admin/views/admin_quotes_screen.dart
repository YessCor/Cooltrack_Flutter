import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/api_client.dart';
import '../../../models/quote.dart';

final quotesProvider = FutureProvider<List<Quote>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/quotes');
  final List<dynamic> data = response['data'];
  return data.map((e) => Quote.fromJson(e)).toList();
});

class AdminQuotesScreen extends ConsumerWidget {
  const AdminQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(quotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
      ),
      body: quotesAsync.when(
        data: (quotes) => quotes.isEmpty
            ? const Center(child: Text('No hay cotizaciones'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        child: Text('#${quote.quoteNumber}',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                      ),
                      title: Text('Cotización #${quote.quoteNumber}'),
                      subtitle: Text(quote.formattedTotal),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(quote.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quote.statusLabel,
                          style: TextStyle(fontSize: 12, color: _getStatusColor(quote.status)),
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // New quote
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return AppColors.textMuted;
      case QuoteStatus.sent:
        return AppColors.info;
      case QuoteStatus.approved:
        return AppColors.success;
      case QuoteStatus.rejected:
        return AppColors.error;
      case QuoteStatus.expired:
        return AppColors.warning;
    }
  }
}