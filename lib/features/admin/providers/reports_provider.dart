import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechPerformance {
  final String name;
  final int completedOrders;
  final double averageRating;

  TechPerformance({required this.name, required this.completedOrders, required this.averageRating});
}

class RevenueByService {
  final String serviceType;
  final double amount;

  RevenueByService({required this.serviceType, required this.amount});
}

final reportsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;

  // 1. Rendimiento por Técnico
  final techPerformanceResponse = await supabase
      .from('service_orders')
      .select('technician_id, client_rating, status, users!service_orders_technician_id_fkey(name)')
      .eq('status', 'completed');

  final Map<String, List<double>> techStats = {};
  final Map<String, String> techNames = {};

  for (var row in techPerformanceResponse) {
    final techId = row['technician_id'] as String?;
    if (techId == null) continue;
    
    final techName = (row['users'] as Map)['name'] as String;
    techNames[techId] = techName;
    
    final rating = (row['client_rating'] as num?)?.toDouble() ?? 0.0;
    if (!techStats.containsKey(techId)) techStats[techId] = [];
    if (rating > 0) techStats[techId]!.add(rating);
  }

  final List<TechPerformance> performances = techStats.entries.map((e) {
    final avgRating = e.value.isEmpty ? 0.0 : e.value.reduce((a, b) => a + b) / e.value.length;
    return TechPerformance(
      name: techNames[e.key] ?? 'Unknown',
      completedOrders: e.value.length,
      averageRating: avgRating,
    );
  }).toList();

  // 2. Ingresos por Tipo de Servicio
  final revenueResponse = await supabase
      .from('service_orders')
      .select('service_type, total_amount')
      .eq('status', 'completed');

  final Map<String, double> revenueMap = {};
  for (var row in revenueResponse) {
    final type = row['service_type'] as String? ?? 'Otros';
    final amount = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
    revenueMap[type] = (revenueMap[type] ?? 0.0) + amount;
  }

  final List<RevenueByService> revenues = revenueMap.entries
      .map((e) => RevenueByService(serviceType: e.key, amount: e.value))
      .toList();

  return {
    'tech_performance': performances,
    'revenue_by_service': revenues,
  };
});
