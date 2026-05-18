class ServiceCatalog {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final double basePrice;
  final String unit;
  final bool isActive;
  final DateTime createdAt;

  ServiceCatalog({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.basePrice,
    this.unit = 'servicio',
    this.isActive = true,
    required this.createdAt,
  });

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) {
    return ServiceCatalog(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'servicio',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'base_price': basePrice,
      'unit': unit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
