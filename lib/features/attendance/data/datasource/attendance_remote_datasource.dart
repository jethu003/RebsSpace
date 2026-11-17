
import 'package:rebsspace/core/network/api_client.dart';
import 'package:rebsspace/features/attendance/data/models/attendance_event_model.dart';
import 'package:rebsspace/features/attendance/data/models/attendance_model.dart';


class AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSource(this.apiClient);

  Future<List<AttendanceModel>> getAttendance(String month) async {
    final response = await apiClient.dio.get(
      '/attendance',
      queryParameters: {'month': month},
    );

    final List records = response.data['attendance'];

    return records
        .map((record) => AttendanceModel.fromJson(record))
        .toList();
  }

  Future<Map<String, dynamic>> submitAttendance(
    AttendanceEventModel event,
  ) async {
    final response = await apiClient.dio.post(
      '/attendance/events',
      data: event.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }
}
