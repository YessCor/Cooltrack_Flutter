import 'dart:convert';
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

  // Orders
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    final box = Hive.box(_ordersBox);
    await box.put('orders', jsonEncode(orders));
  }

  List<Map<String, dynamic>> getCachedOrders() {
    final box = Hive.box(_ordersBox);
    final data = box.get('orders');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> addPendingOrder(Map<String, dynamic> order) async {
    final box = Hive.box(_ordersBox);
    final pending = box.get('pending_orders') ?? [];
    pending.add(order);
    await box.put('pending_orders', pending);
  }

  List<Map<String, dynamic>> getPendingOrders() {
    final box = Hive.box(_ordersBox);
    final data = box.get('pending_orders');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  // Equipment
  Future<void> cacheEquipment(List<Map<String, dynamic>> equipment) async {
    final box = Hive.box(_equipmentBox);
    await box.put('equipment', jsonEncode(equipment));
  }

  List<Map<String, dynamic>> getCachedEquipment() {
    final box = Hive.box(_equipmentBox);
    final data = box.get('equipment');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Quotes
  Future<void> cacheQuotes(List<Map<String, dynamic>> quotes) async {
    final box = Hive.box(_quotesBox);
    await box.put('quotes', jsonEncode(quotes));
  }

  List<Map<String, dynamic>> getCachedQuotes() {
    final box = Hive.box(_quotesBox);
    final data = box.get('quotes');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Sync Queue
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final box = Hive.box(_syncQueueBox);
    final queue = box.get('queue') ?? [];
    queue.add({
      ...item,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.put('queue', queue);
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final box = Hive.box(_syncQueueBox);
    final data = box.get('queue');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> clearSyncQueue() async {
    final box = Hive.box(_syncQueueBox);
    await box.delete('queue');
  }

  Future<void> removeSyncItem(int index) async {
    final box = Hive.box(_syncQueueBox);
    final queue = box.get('queue') ?? [];
    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      await box.put('queue', queue);
    }
  }

  // Settings
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  // Last sync
  Future<void> setLastSyncTime(DateTime time) async {
    await saveSetting('last_sync', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeStr = getSetting<String>('last_sync');
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await Hive.box(_ordersBox).clear();
    await Hive.box(_equipmentBox).clear();
    await Hive.box(_quotesBox).clear();
    await Hive.box(_syncQueueBox).clear();
  }
}