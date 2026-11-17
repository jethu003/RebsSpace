
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:rebsspace/core/services/location_services.dart';
import 'package:rebsspace/core/database/app_database.dart';

import 'package:rebsspace/features/attendance/data/datasource/attendance_remote_datasource.dart';
import 'package:rebsspace/features/attendance/data/models/attendance_event_model.dart';
import 'package:rebsspace/features/attendance/data/models/attendance_model.dart';

class AttendanceController extends GetxController {
  final AttendanceRemoteDataSource remoteDataSource;
  final LocationService locationService;
  final AppDatabase database;

  AttendanceController({
    required this.remoteDataSource,
    required this.locationService,
    required this.database,
  });

  // Office configuration
  static const double officeLatitude = 9.743375;
  static const double officeLongitude = 77.2096917;
  static const double officeRadius = 200;

  // Reactive states
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final isSyncing = false.obs;

  final attendanceRecords = <AttendanceModel>[].obs;
  final localEvents = <Map<String, dynamic>>[].obs;

  final todayCheckIn = RxnString();
  final todayCheckOut = RxnString();

  final errorMessage = ''.obs;

  final Uuid _uuid = const Uuid();

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  String get today =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get currentMonth =>
      DateFormat('yyyy-MM').format(DateTime.now());

  String get todayStatus {
    if (todayCheckOut.value != null) {
      return 'Checked Out';
    }

    if (todayCheckIn.value != null) {
      return 'Checked In';
    }

    return 'Not Checked In';
  }

  int get pendingCount => localEvents
      .where((event) => event['syncStatus'] == 'PENDING')
      .length;

  int get rejectedCount => localEvents
      .where((event) => event['syncStatus'] == 'REJECTED')
      .length;

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    _listenToConnectivity();

    loadAttendance();
  }

  // --------------------------------------------------
  // LOAD ATTENDANCE
  // --------------------------------------------------

  Future<void> loadAttendance() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response =
          await remoteDataSource.getAttendance(currentMonth);

      attendanceRecords.assignAll(response);

      await database.cacheAttendance(
        response.map((item) => {
          'date': item.date,
          'checkIn': item.checkIn,
          'checkOut': item.checkOut,
          'status': item.status,
        }).toList(),
      );
    } catch (e) {
      debugPrint('Attendance loading error: $e');

      try {
        final cached = await database.getCachedAttendance();

        if (cached.isNotEmpty) {
          attendanceRecords.assignAll(
            cached.map((item) => AttendanceModel(
              date: item['date'] as String,
              checkIn: item['checkIn'] as String?,
              checkOut: item['checkOut'] as String?,
              status: item['status'] as String,
            )),
          );
        } else {
          errorMessage.value =
              'Unable to load attendance history.';
        }
      } catch (cacheError) {
        errorMessage.value =
            'Unable to load attendance history.';
        debugPrint('Cache loading error: $cacheError');
      }
    } finally {
      _updateTodayFromRecords();
      await loadLocalEvents();
      isLoading.value = false;
    }
  }

  void _updateTodayFromRecords() {
    final record = attendanceRecords.firstWhereOrNull(
      (item) => item.date == today,
    );

    todayCheckIn.value = record?.checkIn;
    todayCheckOut.value = record?.checkOut;
  }

  Future<void> loadLocalEvents() async {
    final events = await database.getAllEvents();

    localEvents.assignAll(events);

    _updateTodayFromLocalEvents();
  }

  void _updateTodayFromLocalEvents() {
    final events = localEvents
        .where((event) =>
            (event['timestamp'] as String).startsWith(today))
        .toList()
      ..sort((a, b) =>
          (a['createdAt'] as String)
              .compareTo(b['createdAt'] as String));

    for (final event in events) {
      if (event['syncStatus'] == 'REJECTED') {
        continue;
      }

      if (event['eventType'] == 'CHECK_IN') {
        todayCheckIn.value ??= event['timestamp'] as String;
      }

      if (event['eventType'] == 'CHECK_OUT') {
        todayCheckOut.value ??= event['timestamp'] as String;
      }
    }
  }

  // --------------------------------------------------
  // CHECK IN / CHECK OUT
  // --------------------------------------------------

  Future<void> checkIn() async {
    await _recordAttendance('CHECK_IN');
  }

  Future<void> checkOut() async {
    await _recordAttendance('CHECK_OUT');
  }

  Future<void> _recordAttendance(String eventType) async {
    if (isProcessing.value) return;

    if (eventType == 'CHECK_IN' &&
        todayCheckIn.value != null) {
      Get.snackbar(
        'Attendance',
        'You have already checked in today.',
      );
      return;
    }

    if (eventType == 'CHECK_OUT' &&
        todayCheckIn.value == null) {
      Get.snackbar(
        'Attendance',
        'Please check in before checking out.',
      );
      return;
    }

    if (eventType == 'CHECK_OUT' &&
        todayCheckOut.value != null) {
      Get.snackbar(
        'Attendance',
        'You have already checked out today.',
      );
      return;
    }

    isProcessing.value = true;

    try {
      // Get current GPS position
      final position =
          await locationService.getCurrentPosition();

      // Calculate distance from office
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLatitude,
        officeLongitude,
      );

      debugPrint('----------------------------');
      debugPrint('Current latitude: ${position.latitude}');
      debugPrint('Current longitude: ${position.longitude}');
      debugPrint('Office latitude: $officeLatitude');
      debugPrint('Office longitude: $officeLongitude');
      debugPrint(
        'Distance from office: ${distance.toStringAsFixed(2)} metres',
      );
      debugPrint('----------------------------');

      // Validate office radius
      if (distance > officeRadius) {
        throw Exception(
          'You are ${distance.toStringAsFixed(0)} metres away '
          'from the office. You must be within '
          '$officeRadius metres to mark attendance.',
        );
      }

      // Create attendance event
      final timestamp = DateTime.now().toIso8601String();

      final event = AttendanceEventModel(
        eventId: _uuid.v4(),
        eventType: eventType,
        timestamp: timestamp,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Save locally first
      await database.insertPendingEvent(event.toJson());

      // Update UI immediately
      if (eventType == 'CHECK_IN') {
        todayCheckIn.value = timestamp;
      } else {
        todayCheckOut.value = timestamp;
      }

      await loadLocalEvents();

      // Attempt immediate synchronization
      await syncPendingEvents();

      Get.snackbar(
        'Attendance saved',
        'Your $eventType event has been recorded locally.',
      );
    } catch (e) {
      debugPrint('Attendance error: $e');

      Get.snackbar(
        'Attendance',
        _friendlyError(e),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // --------------------------------------------------
  // INTERNET CONNECTIVITY
  // --------------------------------------------------

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();

    return result.any(
      (item) => item != ConnectivityResult.none,
    );
  }

  // Automatic connectivity listener
  void _listenToConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOnline = results.any(
          (result) => result != ConnectivityResult.none,
        );

        if (isOnline) {
          debugPrint(
            'Internet connection restored. Starting automatic sync...',
          );

          syncPendingEvents();
        } else {
          debugPrint(
            'Internet disconnected. Events will remain pending.',
          );
        }
      },
      onError: (error) {
        debugPrint('Connectivity listener error: $error');
      },
    );
  }

  // --------------------------------------------------
  // SYNC PENDING EVENTS
  // --------------------------------------------------

  Future<void> syncPendingEvents() async {
    if (isSyncing.value) return;

    isSyncing.value = true;

    try {
      final online = await _isOnline();

      if (!online) {
        debugPrint(
          'Offline. Attendance events are waiting for sync.',
        );
        return;
      }

      // Get pending events in creation order
      final pending = await database.getPendingEvents();

      if (pending.isEmpty) {
        debugPrint('No pending attendance events.');
        return;
      }

      debugPrint(
        'Starting sync for ${pending.length} pending events.',
      );

      for (final event in pending) {
        try {
          final model = AttendanceEventModel(
            eventId: event['eventId'] as String,
            eventType: event['eventType'] as String,
            timestamp: event['timestamp'] as String,
            latitude: (event['latitude'] as num).toDouble(),
            longitude: (event['longitude'] as num).toDouble(),
          );

          // Submit one event at a time
          await remoteDataSource.submitAttendance(model);

          await database.updateEventStatus(
            eventId: model.eventId,
            status: 'SYNCED',
          );

          debugPrint(
            'Attendance synced: ${model.eventId}',
          );
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;

          if (statusCode == 409 ||
              statusCode == 403 ||
              statusCode == 400) {
            final responseData = e.response?.data;

            final serverMessage =
                responseData is Map
                    ? responseData['message']?.toString()
                    : null;

            await database.updateEventStatus(
              eventId: event['eventId'] as String,
              status: 'REJECTED',
              errorMessage: serverMessage ??
                  'Attendance rejected by server.',
            );

            // Stop if an earlier event is rejected
            break;
          } else {
            // Keep event PENDING for retry
            debugPrint(
              'Sync failed. Event remains pending: $e',
            );
            break;
          }
        } catch (e) {
          debugPrint('Attendance sync error: $e');
          break;
        }
      }

      await loadLocalEvents();
      await loadAttendance();
    } finally {
      isSyncing.value = false;
    }
  }

  // --------------------------------------------------
  // ERROR MESSAGES
  // --------------------------------------------------

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }

    return 'Unable to record attendance. $message';
  }

  // --------------------------------------------------
  // CLEANUP
  // --------------------------------------------------

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
