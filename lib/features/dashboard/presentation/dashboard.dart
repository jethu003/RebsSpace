
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rebsspace/core/app_colors.dart';
import 'package:rebsspace/core/app_widgets.dart';

import 'package:rebsspace/features/attendance/presentation/controllers/attendance_controllers.dart';
import 'package:rebsspace/features/dashboard/presentation/controllers/dashboard_controllor.dart';
import 'package:rebsspace/features/leave/presentation/controllers/leave_controller.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController dashboardController =
      Get.find<DashboardController>();

  final AttendanceController attendanceController =
      Get.find<AttendanceController>();

  final LeaveController leaveController =
      Get.find<LeaveController>();

  // FORMAT TIME
  String formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '--:--';
    }

    final date = DateTime.tryParse(value);

    if (date != null) {
      return DateFormat('hh:mm a').format(date.toLocal());
    }

    try {
      final parsedTime = DateFormat('HH:mm').parseStrict(value);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (_) {
      return value;
    }
  }

  // FORMAT DATE
  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  // STATUS COLOR
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'checked in':
      case 'checked out':
      case 'approved':
      case 'synced':
        return Colors.green;

      case 'absent':
      case 'rejected':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              dashboardController.fetchDashboard(),
              attendanceController.loadAttendance(),
              leaveController.loadLeaveData(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // EMPLOYEE DETAILS
                Obx(() {
                  if (dashboardController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final employee =
                      dashboardController.employee.value;

                  if (employee == null) {
                    return AppCard(
                      child: Column(
                        children: [
                          Text(
                            dashboardController.errorMessage.value,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed:
                                dashboardController.fetchDashboard,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${employee.employeeName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            InfoTile(
                              icon: Icons.badge_outlined,
                              title: 'Employee ID',
                              value: employee.employeeId,
                            ),

                            const SizedBox(width: 10),

                            InfoTile(
                              icon: Icons.business_outlined,
                              title: 'Department',
                              value: employee.department,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // TODAY'S ATTENDANCE
                const SectionTitle(
                  title: "Today's Attendance",
                ),

                const SizedBox(height: 12),

                Obx(() {
                  final status =
                      attendanceController.todayStatus;

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'Attendance Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            StatusChip(
                              label: status,
                              color: getStatusColor(status),
                              backgroundColor:
                                  AppColors.background,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _AttendanceTimeItem(
                                title: 'Check In',
                                time: formatTime(
                                  attendanceController
                                      .todayCheckIn.value,
                                ),
                              ),
                            ),

                            Expanded(
                              child: _AttendanceTimeItem(
                                title: 'Check Out',
                                time: formatTime(
                                  attendanceController
                                      .todayCheckOut.value,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (attendanceController.pendingCount > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.sync,
                                size: 16,
                                color: Colors.orange,
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: Text(
                                  '${attendanceController.pendingCount} attendance event(s) waiting to sync',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (attendanceController.rejectedCount > 0)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8),
                            child: Text(
                              '${attendanceController.rejectedCount} attendance event(s) rejected',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // LEAVE BALANCE
                const SectionTitle(
                  title: 'Leave Balance',
                ),

                const SizedBox(height: 12),

                Obx(() {
                  final casual =
                      leaveController.casualBalance.value;

                  final sick =
                      leaveController.sickBalance.value;

                  final total = casual + sick;

                  return AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _LeaveBalanceItem(
                                title: 'Casual Leave',
                                days: casual,
                                color: Colors.blue,
                              ),
                            ),

                            Expanded(
                              child: _LeaveBalanceItem(
                                title: 'Sick Leave',
                                days: sick,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 28),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'Total Available Leave',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            Text(
                              '$total Days',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // RECENT ATTENDANCE
                const SectionTitle(
                  title: 'Recent Attendance',
                ),

                const SizedBox(height: 12),

                Obx(() {
                  if (attendanceController.isLoading.value &&
                      attendanceController.attendanceRecords.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final records = attendanceController
                      .attendanceRecords
                      .take(5)
                      .toList();

                  if (records.isEmpty) {
                    return const AppCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No attendance records available.',
                          ),
                        ),
                      ),
                    );
                  }

                  return AppCard(
                    child: Column(
                      children: records.map((record) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatDate(record.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      '${formatTime(record.checkIn)} - ${formatTime(record.checkOut)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment:
                                      Alignment.centerRight,
                                  child: StatusChip(
                                    label: record.status,
                                    backgroundColor:
                                        AppColors.background,
                                    color: getStatusColor(
                                      record.status,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ATTENDANCE TIME ITEM
class _AttendanceTimeItem extends StatelessWidget {
  final String title;
  final String time;

  const _AttendanceTimeItem({
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          time,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// LEAVE BALANCE ITEM
class _LeaveBalanceItem extends StatelessWidget {
  final String title;
  final int days;
  final Color color;

  const _LeaveBalanceItem({
    required this.title,
    required this.days,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$days',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
