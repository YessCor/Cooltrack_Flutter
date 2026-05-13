import '../core/constants.dart';

class Equipment {
  final String id;
  final String clientId;
  final String name;
  final EquipmentType type;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final double? capacityTons;
  final DateTime? installationDate;
  final DateTime? lastServiceDate;
  final String? locationDescription;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.clientId,
    required this.name,
    required this.type,
    this.brand,
    this.model,
    this.serialNumber,
    this.capacityTons,
    this.installationDate,
    this.lastServiceDate,
    this.locationDescription,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      name: json['name'] as String,
      type: equipmentTypeFromString(json['type'] as String) ?? EquipmentType.other,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      capacityTons: (json['capacity_tons'] as num?)?.toDouble(),
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : null,
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.parse(json['last_service_date'] as String)
          : null,
      locationDescription: json['location_description'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'name': name,
      'type': equipmentTypeToString(type),
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'capacity_tons': capacityTons,
      'installation_date': installationDate?.toIso8601String(),
      'last_service_date': lastServiceDate?.toIso8601String(),
      'location_description': locationDescription,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Equipment copyWith({
    String? id,
    String? clientId,
    String? name,
    EquipmentType? type,
    String? brand,
    String? model,
    String? serialNumber,
    double? capacityTons,
    DateTime? installationDate,
    DateTime? lastServiceDate,
    String? locationDescription,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      capacityTons: capacityTons ?? this.capacityTons,
      installationDate: installationDate ?? this.installationDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      locationDescription: locationDescription ?? this.locationDescription,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeLabel => equipmentTypeLabels[type] ?? 'Otro';
}