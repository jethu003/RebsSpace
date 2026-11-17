
import 'package:dio/dio.dart';
import 'package:rebsspace/core/network/api_client.dart';
import 'package:rebsspace/features/leave/data/models/leave_model.dart';


class LeaveRemoteDataSource {
  final Dio dio;

  LeaveRemoteDataSource({required ApiClient apiClient})
      : dio = apiClient.dio;

  // GET /leave/balance
  Future<Map<String, dynamic>> getLeaveBalance() async {
    final response = await dio.get('/leave/balance');

    return Map<String, dynamic>.from(response.data);
  }

  // GET /leave/requests
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await dio.get('/leave/requests');

    final List<dynamic> requests = response.data['requests'];

    return requests.map((item) {
      return LeaveRequestModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // POST /leave/requests
  Future<LeaveRequestModel> submitLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await dio.post(
      '/leave/requests',
      data: {
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );

    return LeaveRequestModel.fromJson(
      Map<String, dynamic>.from(response.data['request']),
    );
  }
}
