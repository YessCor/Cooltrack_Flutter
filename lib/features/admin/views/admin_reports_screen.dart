import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../providers/reports_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes de Rendimiento'),
      ),
      body: reportsAsync.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final List<TechPerformance> techData = data['tech_performance'];
    final List<RevenueByService> revenueData = data['revenue_by_service'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Distribución de Ingresos por Servicio'),
          const SizedBox(height: 16),
          _buildRevenueChart(revenueData),
          const SizedBox(height: 32),
          _buildSectionTitle('Rendimiento de Técnicos (Rating Promedio)'),
          const SizedBox(height: 16),
          _buildTechChart(techData),
          const SizedBox(height: 32),
          _buildSectionTitle('Resumen de Órdenes Completadas'),
          const SizedBox(height: 16),
          _buildTechTable(techData),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildRevenueChart(List<RevenueByService> data) {
    if (data.isEmpty) return const Center(child: Text('No hay datos suficientes'));
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: CardTheme.of(null).shape != null ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: PieChart(
        PieChartData(
          sections: data.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final colors = [AppColors.secondary, AppColors.primary, AppColors.success, AppColors.warning];
            return PieChartSectionData(
              color: colors[idx % colors.length],
              value: item.amount,
              title: '${item.serviceType}\n\$${item.amount.toStringAsFixed(0)}',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTechChart(List<TechPerformance> data) {
    if (data.isEmpty) return const Center(child: Text('No hay datos suficientes'));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.averageRating,
                  color: AppColors.secondary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) => Text(data[val.toInt()].name.split(' ')[0], style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechTable(List<TechPerformance> data) {
    return Card(
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Técnico')),
          DataColumn(label: Text('Órdenes')),
          DataColumn(label: Text('Calificación')),
        ],
        rows: data.map((item) => DataRow(cells: [
          DataCell(Text(item.name)),
          DataCell(Text(item.completedOrders.toString())),
          DataCell(Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text(item.averageRating.toStringAsFixed(1)),
            ],
          )),
        ])).toList(),
      ),
    );
  }
}
