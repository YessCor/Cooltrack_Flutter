import 'package:hive_flutter/hive_flutter.dart';

class OfflineRepository {
  static final OfflineRepository _instance = OfflineRepository._internal();
  factory OfflineRepository() => _instance;
  OfflineRepository._internal();

  static const String _ordersBox = 'offline_orders';
  static const String _equipmentBox = 'offline_equipment';
  static const String _quotesBox = 'offline_quotes';
  static const String _syncQueueBox = 'sync_queue';
  static const String _settingsBox = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_ordersBox);
    await Hive.openBox(_equipmentBox);
    await Hive.openBox(_quotesBox);
    await Hive.openBox(_syncQueueBox);
    await Hive.openBox(_settingsBox);
  }

  // Orders Cache
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    await Hive.box(_ordersBox).put('orders', orders);
  }

  List<Map<String, dynamic>> getCachedOrders() {
    final data = Hive.box(_ordersBox).get('orders');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
  }

  // Equipment Cache
  Future<void> cacheEquipment(List<Map<String, dynamic>> equipment) async {
    await Hive.box(_equipmentBox).put('equipment', equipment);
  }

  List<Map<String, dynamic>> getCachedEquipment() {
    final data = Hive.box(_equipmentBox).get('equipment');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
  }

  // Quotes Cache
  Future<void> cacheQuotes(List<Map<String, dynamic>> quotes) async {
    await Hive.box(_quotesBox).put('quotes', quotes);
  }

  List<Map<String, dynamic>> getCachedQuotes() {
    final data = Hive.box(_quotesBox).get('quotes');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
  }

  // Sync Queue (The "Brain" for offline synchronization)
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final box = Hive.box(_syncQueueBox);
    final List<dynamic> queue = box.get('queue', defaultValue: <dynamic>[]);
    final List<dynamic> updatedQueue = List<dynamic>.from(queue);
    updatedQueue.add({
      ...item,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.put('queue', updatedQueue);
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final data = Hive.box(_syncQueueBox).get('queue');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
  }

  Future<void> removeSyncItem(int index) async {
    final box = Hive.box(_syncQueueBox);
    final List<dynamic> queue = box.get('queue', defaultValue: <dynamic>[]);
    if (index >= 0 && index < queue.length) {
      final List<dynamic> updatedQueue = List<dynamic>.from(queue);
      updatedQueue.removeAt(index);
      await box.put('queue', updatedQueue);
    }
  }

  Future<void> clearSyncQueue() async {
    await Hive.box(_syncQueueBox).delete('queue');
  }

  // Settings & Last Sync
  Future<void> setLastSyncTime(DateTime time) async {
    await Hive.box(_settingsBox).put('last_sync', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeStr = Hive.box(_settingsBox).get('last_sync');
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // Generic settings storage
  Future<void> saveSetting(String key, dynamic value) async {
    await Hive.box(_settingsBox).put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return Hive.box(_settingsBox).get(key, defaultValue: defaultValue) as T?;
  }

  // Clear all cache (useful for Logout)
  Future<void> clearAllCache() async {
    await Hive.box(_ordersBox).clear();
    await Hive.box(_equipmentBox).clear();
    await Hive.box(_quotesBox).clear();
    await Hive.box(_syncQueueBox).clear();
  }
}
