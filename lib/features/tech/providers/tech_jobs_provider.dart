import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/service_order.dart';
import '../../../core/constants.dart';

final techJobsProvider = FutureProvider<List<ServiceOrder>>((ref) async {
  final api = ApiClient();
  final response = await api.get('/orders/technician');
  final List<dynamic> data = response['data'];
  return data.map((e) => ServiceOrder.fromJson(e)).toList();
});

final jobDetailProvider = FutureProvider.family<ServiceOrder, String>((ref, id) async {
  final api = ApiClient();
  final response = await api.get('/orders/$id');
  return ServiceOrder.fromJson(response['data']);
});

class JobUpdateRequest {
  final String orderId;
  final OrderStatus newStatus;
  final String? notes;
  final double? totalAmount;

  JobUpdateRequest({
    required this.orderId,
    required this.newStatus,
    this.notes,
    this.totalAmount,
  });
}

final updateJobStatusProvider = Provider((ref) {
  return (JobUpdateRequest request) async {
    final api = ApiClient();
    await api.patch('/orders/${request.orderId}', data: {
      'status': orderStatusToString(request.newStatus),
      if (request.notes != null) 'technician_notes': request.notes,
      if (request.totalAmount != null) 'total_amount': request.totalAmount,
      if (request.newStatus == OrderStatus.inProgress) 'started_at': DateTime.now().toIso8601String(),
      if (request.newStatus == OrderStatus.completed) 'completed_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(techJobsProvider);
    ref.invalidate(jobDetailProvider(request.orderId));
  };
});