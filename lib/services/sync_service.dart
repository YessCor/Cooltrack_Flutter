import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_repository.dart';
import 'photo_upload_service.dart';

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
  final PhotoUploadService _photoService = PhotoUploadService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
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

      final itemsToProcess = List<Map<String, dynamic>>.from(queue);
      
      for (int i = 0; i < itemsToProcess.length; i++) {
        final item = itemsToProcess[i];
        try {
          final result = await _processSyncItem(item);
          if (result) {
            await _offlineRepo.removeSyncItem(0);
            syncedCount++;
          }
        } catch (e) {
          if (kDebugMode) print('Error syncing item $i: $e');
          break;
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
    final table = item['table'] as String?;
    final data = item['data'] as Map<String, dynamic>?;
    final id = item['id'] as String?;

    switch (action) {
      case 'insert':
        if (table == null || data == null) return false;
        await _supabase.from(table).insert(data);
        return true;
        
      case 'update':
        if (table == null || data == null || id == null) return false;
        await _supabase.from(table).update(data).eq('id', id);
        return true;
        
      case 'delete':
        if (table == null || id == null) return false;
        await _supabase.from(table).delete().eq('id', id);
        return true;

      case 'upload_media':
        return await _processMediaUpload(item);

      case 'upload_signature':
        return await _processSignatureUpload(item);
        
      default:
        return false;
    }
  }

  Future<bool> _processMediaUpload(Map<String, dynamic> item) async {
    final filePath = item['file_path'] as String?;
    final metadata = item['metadata'] as Map<String, dynamic>?;

    if (filePath == null || metadata == null) return false;

    final uploadResult = await _photoService.uploadPhoto(
      filePath, 
      folder: metadata['context'] ?? 'general'
    );

    if (uploadResult.success && uploadResult.url != null) {
      await _supabase.from('media').insert({
        'url': uploadResult.url,
        'public_id': uploadResult.publicId,
        'resource_type': 'image',
        'order_id': metadata['order_id'],
        'equipment_id': metadata['equipment_id'],
        'context': metadata['context'],
        'caption': metadata['caption'],
        'uploaded_by': _supabase.auth.currentUser?.id,
      });

      _deleteLocalFile(filePath);
      return true;
    }
    return false;
  }

  Future<bool> _processSignatureUpload(Map<String, dynamic> item) async {
    final filePath = item['file_path'] as String?;
    final orderId = item['order_id'] as String?;

    if (filePath == null || orderId == null) return false;

    final uploadResult = await _photoService.uploadPhoto(filePath, folder: 'signatures');

    if (uploadResult.success && uploadResult.url != null) {
      await _supabase.from('service_orders').update({
        'client_signature_url': uploadResult.url,
      }).eq('id', orderId);

      _deleteLocalFile(filePath);
      return true;
    }
    return false;
  }

  void _deleteLocalFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  // --- Helpers ---

  Future<void> queueMediaUpload({
    required String filePath,
    String? orderId,
    String? equipmentId,
    String? context,
    String? caption,
  }) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'upload_media',
      'file_path': filePath,
      'metadata': {
        'order_id': orderId,
        'equipment_id': equipmentId,
        'context': context,
        'caption': caption,
      },
    });
  }

  Future<void> queueSignatureUpload(String orderId, String filePath) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'upload_signature',
      'order_id': orderId,
      'file_path': filePath,
    });
  }

  Future<void> queueOrderUpdate(String orderId, Map<String, dynamic> data) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'update',
      'table': 'service_orders',
      'id': orderId,
      'data': data,
    });
  }

  Future<void> queueQuoteUpdate(String quoteId, Map<String, dynamic> data) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'update',
      'table': 'quotes',
      'id': quoteId,
      'data': data,
    });
  }

  Future<void> queueHistoryLog(String orderId, String status, String? notes) async {
    await _offlineRepo.addToSyncQueue({
      'action': 'insert',
      'table': 'service_order_history',
      'data': {
        'order_id': orderId,
        'status': status,
        'notes': notes,
        'changed_by': _supabase.auth.currentUser?.id,
      },
    });
  }

  Future<void> fetchAndCacheAll() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final orders = await _supabase
          .from('service_orders')
          .select()
          .or('technician_id.eq.$userId,client_id.eq.$userId');
      await _offlineRepo.cacheOrders(List<Map<String, dynamic>>.from(orders));

      final equipment = await _supabase.from('equipment').select();
      await _offlineRepo.cacheEquipment(List<Map<String, dynamic>>.from(equipment));

      final quotes = await _supabase.from('quotes').select();
      await _offlineRepo.cacheQuotes(List<Map<String, dynamic>>.from(quotes));
    } catch (e) {
      if (kDebugMode) print('Error fetching data: $e');
    }
  }

  int getPendingCount() => _offlineRepo.getSyncQueue().length;
  DateTime? getLastSyncTime() => _offlineRepo.getLastSyncTime();
}
