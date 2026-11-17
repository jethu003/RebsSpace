
import 'package:rebsspace/core/database/app_database.dart';
import 'package:rebsspace/features/leave/data/models/leave_model.dart';


class LeaveLocalDataSource {
  final AppDatabase database;

  LeaveLocalDataSource({required this.database});

  // Save leave balance in SQLite.
  Future<void> cacheLeaveBalance(
    Map<String, dynamic> balance,
  ) async {
    await database.cacheLeaveBalance(
      casualBalance: balance['casual'] as int,
      sickBalance: balance['sick'] as int,
    );
  }

  // Read cached leave balance.
  Future<Map<String, dynamic>?> getCachedLeaveBalance() async {
    return database.getCachedLeaveBalance();
  }

  // Save leave requests in SQLite.
  Future<void> cacheLeaveRequests(
    List<LeaveRequestModel> requests,
  ) async {
    await database.cacheLeaveRequests(
      requests.map((request) => request.toJson()).toList(),
    );
  }

  // Read cached leave requests.
  Future<List<LeaveRequestModel>> getCachedLeaveRequests() async {
    final records = await database.getCachedLeaveRequests();

    return records.map((record) {
      return LeaveRequestModel.fromJson(record);
    }).toList();
  }
}
