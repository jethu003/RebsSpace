
import '../../../../core/network/api_client.dart';

class EmployeeRemoteDataSource {
  final ApiClient apiClient;

  EmployeeRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> getEmployee() async {
    final response = await apiClient.dio.get('/employee/me');

    return response.data as Map<String, dynamic>;
  }
}
