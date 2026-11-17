
import 'package:get/get.dart';
import 'package:rebsspace/core/database/app_database.dart';
import 'package:rebsspace/core/network/api_client.dart';
import 'package:rebsspace/features/dashboard/data/datasourses/employee_remote_datasourse.dart';
import 'package:rebsspace/features/dashboard/data/models/employe_model.dart';

class DashboardController extends GetxController {
  final ApiClient apiClient;

  DashboardController({
    required this.apiClient,
  });

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final employee = Rxn<EmployeeModel>();

  late final EmployeeRemoteDataSource _dataSource;

  @override
  void onInit() {
    super.onInit();

    _dataSource = EmployeeRemoteDataSource(apiClient);

    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final json = await _dataSource.getEmployee();

      final employeeData = EmployeeModel.fromJson(json);

      employee.value = employeeData;

      await AppDatabase.instance.cacheEmployee({
        'employeeName': employeeData.employeeName,
        'employeeId': employeeData.employeeId,
        'department': employeeData.department,
        'leaveBalance': employeeData.leaveBalance,
      });
    } catch (e) {
      try {
        final cachedData =
            await AppDatabase.instance.getCachedEmployee();

        if (cachedData != null) {
          employee.value = EmployeeModel.fromJson(cachedData);
          errorMessage.value = '';
        } else {
          errorMessage.value =
              'Unable to load employee details. Please check your connection.';
        }
      } catch (cacheError) {
        errorMessage.value =
            'Unable to load employee details.';
      }
    } finally {
      isLoading.value = false;
    }
  }
}
