import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/service_order.dart';
import '../../../core/constants.dart';
import '../../../services/sync_service.dart';
import '../../../services/offline_repository.dart';

final techJobsProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final offlineRepo = OfflineRepository();
  final syncService = SyncService();
  
  try {
    // Intentar refrescar caché desde Supabase si estamos online
    await syncService.fetchAndCacheAll();
  } catch (_) {
    // Si falla el fetch (offline), continuamos con lo que haya en caché
  }

  final cachedData = offlineRepo.getCachedOrders();
  return cachedData.map((e) => ServiceOrder.fromJson(e)).toList();
});

final jobDetailProvider = FutureProvider.family<ServiceOrder, String>((ref, id) async {
  final offlineRepo = OfflineRepository();
  final cachedData = offlineRepo.getCachedOrders();
  
  try {
    final orderMap = cachedData.firstWhere((element) => element['id'] == id);
    return ServiceOrder.fromJson(orderMap);
  } catch (e) {
    // Si no está en caché, intentamos fetch directo
    final response = await Supabase.instance.client
        .from('service_orders')
        .select()
        .eq('id', id)
        .single();
    return ServiceOrder.fromJson(response);
  }
});

class JobUpdateRequest {
  final String orderId;
  final OrderStatus newStatus;
  final String? notes;
  final double? totalAmount;

  JobUpdateRequest({
    required this.orderId,
    required this.newStatus,
    this.notes,
    this.totalAmount,
  });
}

final updateJobStatusProvider = Provider((ref) {
  return (JobUpdateRequest request) async {
    final syncService = SyncService();
    final offlineRepo = OfflineRepository();

    // 1. Preparar data de actualización
    final Map<String, dynamic> updateData = {
      'status': orderStatusToString(request.newStatus),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (request.notes != null) updateData['technician_notes'] = request.notes;
    if (request.totalAmount != null) updateData['total_amount'] = request.totalAmount;
    
    if (request.newStatus == OrderStatus.inProgress) {
      updateData['started_at'] = DateTime.now().toIso8601String();
    } else if (request.newStatus == OrderStatus.completed) {
      updateData['completed_at'] = DateTime.now().toIso8601String();
    }

    // 2. Actualización en Caché Local (Optimista)
    final cachedOrders = offlineRepo.getCachedOrders();
    final index = cachedOrders.indexWhere((o) => o['id'] == request.orderId);
    if (index != -1) {
      cachedOrders[index] = {...cachedOrders[index], ...updateData};
      await offlineRepo.cacheOrders(cachedOrders);
    }

    // 3. Encolar para Sincronización
    await syncService.queueOrderUpdate(request.orderId, updateData);
    
    // Log de historia (también se encola)
    await syncService.queueHistoryLog(
      request.orderId, 
      orderStatusToString(request.newStatus), 
      request.notes
    );

    // 4. Intentar sincronizar ahora mismo si es posible
    syncService.syncAll();

    // 5. Invalidar estados para refrescar UI
    ref.invalidate(techJobsProvider);
    ref.invalidate(jobDetailProvider(request.orderId));
  };
});
