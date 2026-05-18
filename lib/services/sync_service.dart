import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import 'offline_repository.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final bool success;
  final int itemsSynced;
  final String? error;

  SyncResult({
    required this.success,
    this.itemsSynced = 0,
    this.error,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineRepository _offlineRepo = OfflineRepository();
  final ApiClient _api = ApiClient();
  
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  final _listeners = <void Function(SyncStatus)>[];
  void addListener(void Function(SyncStatus) listener) => _listeners.add(listener);
  void removeListener(void Function(SyncStatus) listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_status);
    }
  }

  Future<SyncResult> syncAll() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(success: false, error: 'Sync already in progress');
    }

    _status = SyncStatus.syncing;
    _notifyListeners();

    try {
      final queue = _offlineRepo.getSyncQueue();
      int syncedCount = 0;

      for (int i = queue.length - 1; i >= 0; i--) {
        final item = queue[i];
        try {
          final result = await _processSyncItem(item);
          if (result) {
            await _offlineRepo.removeSyncItem(i);
            syncedCount++;
          }
        } catch (e) {
          if (kDebugMode) print('Error syncing item $i: $e');
        }
      }

      await _offlineRepo.setLastSyncTime(DateTime.now());

      _status = SyncStatus.success;
      _notifyListeners();

      return SyncResult(success: true, itemsSynced: syncedCount);
    } catch (e) {
      _status = SyncStatus.error;
      _notifyListeners();
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    final action = item['action'] as String?;
    final endpoint = item['endpoint'] as String?;
    final data = item['data'] as Map<String, dynamic>?;

    if (endpoint == null) return false;

    switch (action) {
      case 'create':
        await _api.post(endpoint, data: data);
        return true;
      case 'update':
        final id = item['id'] as String?;
        if (id != null) {
          await _api.put('$endpoint/$id', data: data);
          return true;
        }
        return false;
      case 'delete':
        final id = item['id'] as String?;
        if (id != null) {
          await _api.delete('$endpoint/$id');
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  Future<void> queueOrderCreate(Map<String, dynamic> order) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'create',
      'endpoint': '/orders',
      'data': order,
    });
  }

  Future<void> queueOrderUpdate(String orderId, Map<String, dynamic> order) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'update',
      'endpoint': '/orders',
      'id': orderId,
      'data': order,
    });
  }

  Future<void> queueEquipmentCreate(Map<String, dynamic> equipment) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'create',
      'endpoint': '/equipment',
      'data': equipment,
    });
  }

  Future<void> queueQuoteCreate(Map<String, dynamic> quote) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'create',
      'endpoint': '/quotes',
      'data': quote,
    });
  }

  int getPendingCount() {
    return _offlineRepo.getSyncQueue().length;
  }

  DateTime? getLastSyncTime() {
    return _offlineRepo.getLastSyncTime();
  }

  bool hasPendingChanges() {
    return getPendingCount() > 0;
  }

  Future<void> fetchAndCacheData() async {
    try {
      final ordersResponse = await _api.get('/orders');
      final orders = ordersResponse['data'] as List? ?? [];
      await _offlineRepo.cacheOrders(orders.cast<Map<String, dynamic>>());

      final equipmentResponse = await _api.get('/equipment');
      final equipment = equipmentResponse['data'] as List? ?? [];
      await _offlineRepo.cacheEquipment(equipment.cast<Map<String, dynamic>>());

      final quotesResponse = await _api.get('/quotes');
      final quotes = quotesResponse['data'] as List? ?? [];
      await _offlineRepo.cacheQuotes(quotes.cast<Map<String, dynamic>>());
    } catch (e) {
      if (kDebugMode) print('Error fetching data: $e');
    }
  }
}