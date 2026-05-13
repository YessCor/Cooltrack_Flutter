import '../core/api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _api = ApiClient();

  Future<DashboardStats> getStats() async {
    final response = await _api.get('/dashboard/stats');
    return DashboardStats.fromJson(response['data']);
  }
}

final dashboardService = DashboardService();