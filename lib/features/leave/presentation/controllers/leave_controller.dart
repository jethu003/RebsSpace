
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rebsspace/features/leave/data/datasources/leave_local_data_source.dart';
import 'package:rebsspace/features/leave/data/datasources/leave_remote_data_source.dart';
import 'package:rebsspace/features/leave/data/models/leave_model.dart';



class LeaveController extends GetxController {
  final LeaveRemoteDataSource remoteDataSource;
  final LeaveLocalDataSource localDataSource;

  LeaveController({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // Loading states
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isOffline = false.obs;

  // Leave balance
  final casualBalance = 0.obs;
  final sickBalance = 0.obs;

  // Leave history
  final leaveRequests = <LeaveRequestModel>[].obs;

  // Error message
  final errorMessage = ''.obs;

  // Form values
  final selectedLeaveType = 'Casual'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  // Selected leave balance
  int get selectedBalance {
    return selectedLeaveType.value == 'Casual'
        ? casualBalance.value
        : sickBalance.value;
  }

  // Calculate inclusive calendar days
  int get requestedDays {
    final start = startDate.value;
    final end = endDate.value;

    if (start == null || end == null) return 0;

    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);

    return endOnly.difference(startOnly).inDays + 1;
  }

  @override
  void onInit() {
    super.onInit();
    loadLeaveData();
  }

  // --------------------------------------------------
  // LOAD LEAVE DATA FROM API
  // --------------------------------------------------

  Future<void> loadLeaveData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final balance = await remoteDataSource.getLeaveBalance();
      final requests = await remoteDataSource.getLeaveRequests();

      casualBalance.value =
          (balance['casual'] as num).toInt();

      sickBalance.value =
          (balance['sick'] as num).toInt();

      leaveRequests.assignAll(requests);

      // Save API data locally
      await localDataSource.cacheLeaveBalance(balance);
      await localDataSource.cacheLeaveRequests(requests);

      isOffline.value = false;
    } catch (e) {
      debugPrint('Leave API error: $e');

      isOffline.value = true;

      await loadCachedLeaveData();
    } finally {
      isLoading.value = false;
    }
  }

  // --------------------------------------------------
  // LOAD CACHED DATA FROM SQLITE
  // --------------------------------------------------

  Future<void> loadCachedLeaveData() async {
    try {
      final cachedBalance =
          await localDataSource.getCachedLeaveBalance();

      final cachedRequests =
          await localDataSource.getCachedLeaveRequests();

      if (cachedBalance != null) {
        casualBalance.value =
            (cachedBalance['casualBalance'] as num).toInt();

        sickBalance.value =
            (cachedBalance['sickBalance'] as num).toInt();
      }

      leaveRequests.assignAll(cachedRequests);

      if (cachedBalance == null && cachedRequests.isEmpty) {
        errorMessage.value = 'No cached leave data available.';
      }
    } catch (e) {
      debugPrint('Local leave data error: $e');
      errorMessage.value = 'Unable to load leave data.';
    }
  }

  // --------------------------------------------------
  // FORM UPDATES
  // --------------------------------------------------

  void changeLeaveType(String type) {
    selectedLeaveType.value = type;
  }

  void changeStartDate(DateTime date) {
    startDate.value = date;

    // Clear end date if it is earlier than the new start date.
    if (endDate.value != null) {
      final end = endDate.value!;

      final endOnly = DateTime(end.year, end.month, end.day);
      final startOnly = DateTime(date.year, date.month, date.day);

      if (endOnly.isBefore(startOnly)) {
        endDate.value = null;
      }
    }
  }

  void changeEndDate(DateTime date) {
    endDate.value = date;
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  String? validateLeaveRequest(String reason) {
    final start = startDate.value;
    final end = endDate.value;

    if (start == null) {
      return 'Please select a start date.';
    }

    if (end == null) {
      return 'Please select an end date.';
    }

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final startOnly = DateTime(
      start.year,
      start.month,
      start.day,
    );

    final endOnly = DateTime(
      end.year,
      end.month,
      end.day,
    );

    if (startOnly.isBefore(todayOnly)) {
      return 'Start date cannot be in the past.';
    }

    if (endOnly.isBefore(startOnly)) {
      return 'End date cannot be before start date.';
    }

    if (reason.trim().length < 10) {
      return 'Reason must contain at least 10 characters.';
    }

    if (requestedDays > selectedBalance) {
      return 'Insufficient leave balance.';
    }

    if (hasOverlappingLeave(startOnly, endOnly)) {
      return 'You already have a pending or approved leave during these dates.';
    }

    return null;
  }

  // --------------------------------------------------
  // CHECK OVERLAPPING LEAVE REQUESTS
  // --------------------------------------------------

  bool hasOverlappingLeave(DateTime start, DateTime end) {
    for (final request in leaveRequests) {
      final status = request.status.toLowerCase();

      // Only pending and approved requests block new requests.
      if (status != 'pending' && status != 'approved') {
        continue;
      }

      final existingStart = DateTime.tryParse(request.startDate);
      final existingEnd = DateTime.tryParse(request.endDate);

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final existingStartOnly = DateTime(
        existingStart.year,
        existingStart.month,
        existingStart.day,
      );

      final existingEndOnly = DateTime(
        existingEnd.year,
        existingEnd.month,
        existingEnd.day,
      );

      // Inclusive overlap check.
      if (!start.isAfter(existingEndOnly) &&
          !end.isBefore(existingStartOnly)) {
        return true;
      }
    }

    return false;
  }

  // --------------------------------------------------
  // CHECK INTERNET CONNECTIVITY
  // --------------------------------------------------

  Future<bool> isInternetAvailable() async {
    final results = await Connectivity().checkConnectivity();

    return results.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  // --------------------------------------------------
  // SUBMIT LEAVE REQUEST
  // --------------------------------------------------

  Future<bool> submitLeaveRequest(String reason) async {
    if (isSubmitting.value) return false;

    // Validate form
    final validationError = validateLeaveRequest(reason);

    if (validationError != null) {
      Get.snackbar(
        'Invalid Request',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    isSubmitting.value = true;

    try {
      // Check internet before submission
      final online = await isInternetAvailable();

      if (!online) {
        isOffline.value = true;

        Get.snackbar(
          'No Internet',
          'Internet connection is required to submit a leave request.',
          snackPosition: SnackPosition.BOTTOM,
        );

        return false;
      }

      final start = startDate.value!;
      final end = endDate.value!;

      // Format dates as YYYY-MM-DD
      final formattedStart =
          '${start.year.toString().padLeft(4, '0')}-'
          '${start.month.toString().padLeft(2, '0')}-'
          '${start.day.toString().padLeft(2, '0')}';

      final formattedEnd =
          '${end.year.toString().padLeft(4, '0')}-'
          '${end.month.toString().padLeft(2, '0')}-'
          '${end.day.toString().padLeft(2, '0')}';

      // Submit to backend
      final request = await remoteDataSource.submitLeaveRequest(
        leaveType: selectedLeaveType.value,
        startDate: formattedStart,
        endDate: formattedEnd,
        reason: reason.trim(),
      );

      // Refresh data from server after successful submission.
      await loadLeaveData();

      // Reset form
      selectedLeaveType.value = 'Casual';
      startDate.value = null;
      endDate.value = null;

      Get.snackbar(
        'Success',
        'Leave request submitted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } on DioException catch (e) {
      debugPrint('Leave submission error: ${e.message}');

      String message = 'Unable to submit leave request.';

      final responseData = e.response?.data;

      if (responseData is Map &&
          responseData['message'] != null) {
        message = responseData['message'].toString();
      }

      Get.snackbar(
        'Submission Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } catch (e) {
      debugPrint('Unexpected leave submission error: $e');

      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
