import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class Part {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? sku;
  final int stock;

  Part({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.sku,
    this.stock = 0,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      sku: json['sku'] as String?,
      stock: json['stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sku': sku,
      'stock': stock,
    };
  }
}

final partsListProvider = FutureProvider<List<Part>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/parts');
  final List<dynamic> data = response['data'] ?? [];
  return data.map((e) => Part.fromJson(e)).toList();
});

class SelectedPart {
  final String partId;
  final int quantity;
  final double unitPrice;

  SelectedPart({
    required this.partId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'part_id': partId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class PartsNotifier extends StateNotifier<List<SelectedPart>> {
  PartsNotifier() : super([]);

  void addPart(String partId, int quantity, double unitPrice) {
    final existingIndex = state.indexWhere((p) => p.partId == partId);
    if (existingIndex >= 0) {
      final updated = [...state];
      final existing = updated[existingIndex];
      updated[existingIndex] = SelectedPart(
        partId: partId,
        quantity: existing.quantity + quantity,
        unitPrice: unitPrice,
      );
      state = updated;
    } else {
      state = [...state, SelectedPart(partId: partId, quantity: quantity, unitPrice: unitPrice)];
    }
  }

  void removePart(String partId) {
    state = state.where((p) => p.partId != partId).toList();
  }

  void updateQuantity(String partId, int quantity) {
    if (quantity <= 0) {
      removePart(partId);
      return;
    }
    state = state.map((p) {
      if (p.partId == partId) {
        return SelectedPart(partId: partId, quantity: quantity, unitPrice: p.unitPrice);
      }
      return p;
    }).toList();
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, p) => sum + (p.quantity * p.unitPrice));
}

final selectedPartsProvider = StateNotifierProvider<PartsNotifier, List<SelectedPart>>((ref) {
  return PartsNotifier();
});

final partsTotalProvider = Provider<double>((ref) {
  final parts = ref.watch(selectedPartsProvider);
  return parts.fold(0, (sum, p) => sum + (p.quantity * p.unitPrice));
});