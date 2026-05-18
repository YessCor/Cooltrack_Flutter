class Media {
  final String id;
  final String url;
  final String publicId;
  final String resourceType;
  final String? format;
  final int? bytes;
  final String? uploadedBy;
  final String? orderId;
  final String? equipmentId;
  final String? context;
  final String? caption;
  final DateTime createdAt;

  Media({
    required this.id,
    required this.url,
    required this.publicId,
    required this.resourceType,
    this.format,
    this.bytes,
    this.uploadedBy,
    this.orderId,
    this.equipmentId,
    this.context,
    this.caption,
    required this.createdAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      url: json['url'] as String,
      publicId: json['public_id'] as String,
      resourceType: json['resource_type'] as String,
      format: json['format'] as String?,
      bytes: json['bytes'] as int?,
      uploadedBy: json['uploaded_by'] as String?,
      orderId: json['order_id'] as String?,
      equipmentId: json['equipment_id'] as String?,
      context: json['context'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'public_id': publicId,
      'resource_type': resourceType,
      'format': format,
      'bytes': bytes,
      'uploaded_by': uploadedBy,
      'order_id': orderId,
      'equipment_id': equipmentId,
      'context': context,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
