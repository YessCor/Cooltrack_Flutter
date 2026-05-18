import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/dashboard_stats.dart';
import '../../../models/service_order.dart';

import '../../../models/service_catalog.dart';

final adminDashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final supabase = Supabase.instance.client;
  
  // 1. Total orders
  final totalOrdersResponse = await supabase
      .from('service_orders')
      .select('id', const FetchOptions(count: CountOption.exact));
  final totalOrders = totalOrdersResponse.count ?? 0;

  // 2. Active orders (pending, assigned, accepted, in_transit, in_progress)
  final activeOrdersResponse = await supabase
      .from('service_orders')
      .select('id', const FetchOptions(count: CountOption.exact))
      .in_('status', ['pending', 'assigned', 'accepted', 'in_transit', 'in_progress']);
  final activeOrders = activeOrdersResponse.count ?? 0;

  // 3. Completed orders
  final completedOrdersResponse = await supabase
      .from('service_orders')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('status', 'completed');
  final completedOrders = completedOrdersResponse.count ?? 0;

  // 4. Pending quotes
  final pendingQuotesResponse = await supabase
      .from('quotes')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('status', 'sent');
  final pendingQuotes = pendingQuotesResponse.count ?? 0;

  // 5. Total revenue (sum of total_amount from completed orders)
  final revenueResponse = await supabase
      .from('service_orders')
      .select('total_amount')
      .eq('status', 'completed');
  
  double totalRevenue = 0;
  for (var row in revenueResponse) {
    totalRevenue += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
  }

  // 6. Average rating
  final ratingResponse = await supabase
      .from('service_orders')
      .select('client_rating')
      .not('client_rating', 'is', null);
  
  double averageRating = 0;
  if (ratingResponse.isNotEmpty) {
    double sum = 0;
    for (var row in ratingResponse) {
      sum += (row['client_rating'] as num).toDouble();
    }
    averageRating = sum / ratingResponse.length;
  }

  return DashboardStats(
    totalOrders: totalOrders,
    activeOrders: activeOrders,
    completedOrders: completedOrders,
    pendingQuotes: pendingQuotes,
    totalRevenue: totalRevenue,
    averageRating: averageRating,
  );
});

final recentOrdersProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('service_orders')
      .select()
      .order('created_at', ascending: false)
      .limit(5);
  
  return (response as List).map((e) => ServiceOrder.fromJson(e)).toList();
});

final techniciansProvider = FutureProvider<List<User>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('users')
      .select()
      .eq('role', 'technician')
      .eq('is_active', true);
  
  return (response as List).map((e) => User.fromJson(e)).toList();
});

final allClientsProvider = FutureProvider<List<User>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('users')
      .select()
      .eq('role', 'client')
      .eq('is_active', true);
  
  return (response as List).map((e) => User.fromJson(e)).toList();
});

final adminOrderDetailProvider = FutureProvider.family<ServiceOrder?, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('service_orders')
        .select()
        .eq('id', id)
        .single();
    return ServiceOrder.fromJson(response);
  } catch (e) {
    return null;
  }
});

final serviceCatalogProvider = FutureProvider<List<ServiceCatalog>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('service_catalog')
      .select()
      .order('name');
  
  return (response as List).map((e) => ServiceCatalog.fromJson(e)).toList();
});

final updateServicePriceProvider = Provider((ref) {
  return (String id, double newPrice) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('service_catalog')
        .update({'base_price': newPrice})
        .eq('id', id);
    ref.invalidate(serviceCatalogProvider);
  };
});


