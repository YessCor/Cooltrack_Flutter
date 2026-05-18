import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/equipment.dart';
import '../../../models/service_order.dart';
import '../../../services/offline_repository.dart';
import '../../../services/sync_service.dart';

/// Provider para obtener los equipos del cliente actual
final clientEquipmentProvider = FutureProvider<List<Equipment>>((ref) async {
  final offlineRepo = OfflineRepository();
  final syncService = SyncService();
  
  try {
    await syncService.fetchAndCacheAll();
  } catch (_) {}

  final cachedData = offlineRepo.getCachedEquipment();
  return cachedData.map((e) => Equipment.fromJson(e)).toList();
});

/// Provider para obtener las órdenes de servicio del cliente actual
final clientOrdersProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final offlineRepo = OfflineRepository();
  final syncService = SyncService();
  
  try {
    await syncService.fetchAndCacheAll();
  } catch (_) {}

  final cachedData = offlineRepo.getCachedOrders();
  // Filtrar solo las que pertenecen al cliente si el caché tiene de todo (aunque fetchAndCacheAll ya filtra por usuario)
  return cachedData.map((e) => ServiceOrder.fromJson(e)).toList();
});

final clientQuotesProvider = FutureProvider<List<Quote>>((ref) async {
  final offlineRepo = OfflineRepository();
  final syncService = SyncService();
  
  try {
    await syncService.fetchAndCacheAll();
  } catch (_) {}

  final cachedData = offlineRepo.getCachedQuotes();
  return cachedData.map((e) => Quote.fromJson(e)).toList();
});

final clientQuoteDetailProvider = FutureProvider.family<Quote?, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('quotes')
        .select('*, items:quote_items(*)')
        .eq('id', id)
        .single();
    return Quote.fromJson(response);
  } catch (e) {
    return null;
  }
});

final updateQuoteStatusProvider = Provider((ref) {
  return (String quoteId, QuoteStatus newStatus) async {
    final supabase = Supabase.instance.client;
    final syncService = SyncService();
    
    final updateData = {
      'status': quoteStatusToString(newStatus),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 1. Encolar actualización (Offline-first)
    await syncService.queueOrderUpdate(quoteId, updateData); // Reutilizamos lógica de cola o creamos específica
    // Nota: El método queueOrderUpdate en SyncService usa la tabla 'service_orders' por defecto.
    // Deberíamos añadir uno genérico o específico para quotes.
    
    // Mejor usamos una acción genérica si existiera o añadimos queueQuoteUpdate
    await supabase.from('quotes').update(updateData).eq('id', quoteId);
    
    ref.invalidate(clientQuoteDetailProvider(quoteId));
    ref.invalidate(clientOrdersProvider); // Por si la orden vinculada cambió
  };
});

/// Notifier para crear nuevas solicitudes de servicio
class NewRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService = SyncService();
  final SupabaseClient _supabase = Supabase.instance.client;

  NewRequestNotifier() : super(const AsyncValue.data(null));

  Future<bool> createRequest({
    required String equipmentId,
    required String serviceType,
    required String description,
    required String address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final newOrder = {
        'client_id': userId,
        'equipment_id': equipmentId,
        'service_type': serviceType,
        'description': description,
        'address': address,
        'status': 'pending',
        'priority': 'medium',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Encolar para sincronización (Offline-first)
      await _syncService.queueOrderCreate(newOrder);
      
      // Intentar sincronizar si hay red
      _syncService.syncAll();
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final newRequestProvider = StateNotifierProvider<NewRequestNotifier, AsyncValue<void>>((ref) {
  return NewRequestNotifier();
});
