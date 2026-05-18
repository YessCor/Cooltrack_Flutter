import '../core/constants.dart';

class QuoteItem {
  final String id;
  final String quoteId;
  final String? catalogItemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;

  QuoteItem({
    required this.id,
    required this.quoteId,
    this.catalogItemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      catalogItemId: json['catalog_item_id'] as String?,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'catalog_item_id': catalogItemId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Quote {
  final String id;
  final int quoteNumber;
  final String? displayQuoteNumber;
  final String? orderId;
  final String clientId;
  final String? technicianId;
  final QuoteStatus status;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final DateTime? validUntil;
  final String? notes;
  final String? terms;
  final List<QuoteItem>? items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quote({
    required this.id,
    required this.quoteNumber,
    this.displayQuoteNumber,
    this.orderId,
    required this.clientId,
    this.technicianId,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.validUntil,
    this.notes,
    this.terms,
    this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      quoteNumber: json['quote_number'] as int,
      displayQuoteNumber: json['display_quote_number'] as String?,
      orderId: json['order_id'] as String?,
      clientId: json['client_id'] as String,
      technicianId: json['technician_id'] as String?,
      status: quoteStatusFromString(json['status'] as String) ?? QuoteStatus.draft,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => QuoteItem.fromJson(e)).toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_number': quoteNumber,
      'display_quote_number': displayQuoteNumber,
      'order_id': orderId,
      'client_id': clientId,
      'technician_id': technicianId,
      'status': quoteStatusToString(status),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
      'terms': terms,
      'items': items?.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Quote copyWith({
    String? id,
    int? quoteNumber,
    String? displayQuoteNumber,
    String? orderId,
    String? clientId,
    String? technicianId,
    QuoteStatus? status,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    DateTime? validUntil,
    String? notes,
    String? terms,
    List<QuoteItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      displayQuoteNumber: displayQuoteNumber ?? this.displayQuoteNumber,
      orderId: orderId ?? this.orderId,
      clientId: clientId ?? this.clientId,
      technicianId: technicianId ?? this.technicianId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel => quoteStatusLabels[status] ?? 'Desconocido';
  
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
}