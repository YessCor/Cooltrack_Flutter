class DashboardStats {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int pendingQuotes;
  final double totalRevenue;
  final double averageRating;

  DashboardStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingQuotes,
    required this.totalRevenue,
    required this.averageRating,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['totalOrders'] as int? ?? 0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      pendingQuotes: json['pendingQuotes'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'activeOrders': activeOrders,
      'completedOrders': completedOrders,
      'pendingQuotes': pendingQuotes,
      'totalRevenue': totalRevenue,
      'averageRating': averageRating,
    };
  }

  String get formattedRevenue => '\$${totalRevenue.toStringAsFixed(2)}';
  String get formattedRating => averageRating.toStringAsFixed(1);
}