
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rebsspace/features/attendance/presentation/controllers/attendance_controllers.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  String formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';

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

  Color statusColor(String status) {
    switch (status) {
      case 'Checked In':
        return Colors.orange;
      case 'Checked Out':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AttendanceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Sync Now',
              onPressed: controller.isSyncing.value
                  ? null
                  : controller.syncPendingEvents,
              icon: controller.isSyncing.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync),
            ),
          ),
        ],
      ),

      body: Obx(() {
        final checkIn = controller.todayCheckIn.value;
        final checkOut = controller.todayCheckOut.value;
        final status = controller.todayStatus;

        final isProcessing = controller.isProcessing.value;
        final pendingCount = controller.pendingCount;

        return RefreshIndicator(
          onRefresh: controller.loadAttendance,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // TODAY STATUS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Attendance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 35,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor(status),
                              ),
                            ),
                          ),
                          if (pendingCount > 0)
                            Chip(
                              label: Text('$pendingCount Pending'),
                              backgroundColor: Colors.orange.shade100,
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Office location verification required',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-in'),
                          Text(
                            formatTime(checkIn),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-out'),
                          Text(
                            formatTime(checkOut),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ATTENDANCE ACTION
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ||
                          status == 'Checked Out'
                      ? null
                      : () {
                          if (status == 'Not Checked In') {
                            controller.checkIn();
                          } else {
                            controller.checkOut();
                          }
                        },
                  icon: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          status == 'Not Checked In'
                              ? Icons.login
                              : Icons.logout,
                        ),
                  label: Text(
                    isProcessing
                        ? 'Processing...'
                        : status == 'Not Checked In'
                            ? 'Check In'
                            : status == 'Checked In'
                                ? 'Check Out'
                                : 'Attendance Completed',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SYNC STATUS
              Card(
                child: ListTile(
                  leading: Icon(
                    pendingCount > 0
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_done_outlined,
                    color: pendingCount > 0
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(
                    pendingCount > 0
                        ? '$pendingCount events waiting to sync'
                        : 'All attendance events are synced',
                  ),
                  subtitle: Text(
                    controller.isSyncing.value
                        ? 'Synchronizing...'
                        : 'Tap Sync Now to synchronize manually',
                  ),
                  trailing: TextButton(
                    onPressed: controller.isSyncing.value
                        ? null
                        : controller.syncPendingEvents,
                    child: const Text('Sync Now'),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ERROR STATE
              if (controller.errorMessage.value.isNotEmpty)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),

              // ATTENDANCE HISTORY
              const Text(
                'Recent Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (controller.isLoading.value &&
                  controller.attendanceRecords.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (controller.attendanceRecords.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No attendance records available'),
                    ),
                  ),
                )
              else
                ...controller.attendanceRecords
                    .take(5)
                    .map(
                      (record) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.calendar_today),
                          ),
                          title: Text(record.date),
                          subtitle: Text(
                            'In: ${formatTime(record.checkIn)}  |  '
                            'Out: ${formatTime(record.checkOut)}',
                          ),
                          trailing: Text(
                            record.status,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}
