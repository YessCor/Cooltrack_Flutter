import '../core/constants.dart';

class ServiceOrder {
  final String id;
  final int orderNumber;
  final String clientId;
  final String? technicianId;
  final String? equipmentId;
  final OrderStatus status;
  final String priority;
  final String serviceType;
  final String description;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? clientSignatureUrl;
  final String? technicianNotes;
  final int? clientRating;
  final String? clientFeedback;
  final double? totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceOrder({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    this.technicianId,
    this.equipmentId,
    required this.status,
    required this.priority,
    required this.serviceType,
    required this.description,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    required this.address,
    this.latitude,
    this.longitude,
    this.clientSignatureUrl,
    this.technicianNotes,
    this.clientRating,
    this.clientFeedback,
    this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as int,
      clientId: json['client_id'] as String,
      technicianId: json['technician_id'] as String?,
      equipmentId: json['equipment_id'] as String?,
      status: orderStatusFromString(json['status'] as String) ?? OrderStatus.pending,
      priority: json['priority'] as String? ?? 'normal',
      serviceType: json['service_type'] as String? ?? 'maintenance',
      description: json['description'] as String? ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      clientSignatureUrl: json['client_signature_url'] as String?,
      technicianNotes: json['technician_notes'] as String?,
      clientRating: json['client_rating'] as int?,
      clientFeedback: json['client_feedback'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'client_id': clientId,
      'technician_id': technicianId,
      'equipment_id': equipmentId,
      'status': orderStatusToString(status),
      'priority': priority,
      'service_type': serviceType,
      'description': description,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'client_signature_url': clientSignatureUrl,
      'technician_notes': technicianNotes,
      'client_rating': clientRating,
      'client_feedback': clientFeedback,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServiceOrder copyWith({
    String? id,
    int? orderNumber,
    String? clientId,
    String? technicianId,
    String? equipmentId,
    OrderStatus? status,
    String? priority,
    String? serviceType,
    String? description,
    DateTime? scheduledDate,
    DateTime? startedAt,
    DateTime? completedAt,
    String? address,
    double? latitude,
    double? longitude,
    String? clientSignatureUrl,
    String? technicianNotes,
    int? clientRating,
    String? clientFeedback,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      clientId: clientId ?? this.clientId,
      technicianId: technicianId ?? this.technicianId,
      equipmentId: equipmentId ?? this.equipmentId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      clientRating: clientRating ?? this.clientRating,
      clientFeedback: clientFeedback ?? this.clientFeedback,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel => orderStatusLabels[status] ?? 'Desconocido';
  
  bool get isPending => status == OrderStatus.pending;
  bool get isAssigned => status == OrderStatus.assigned;
  bool get isInProgress => status == OrderStatus.inProgress || status == OrderStatus.inTransit;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
}