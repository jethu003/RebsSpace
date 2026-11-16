
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isCheckedIn = false;
  bool isCheckedOut = false;

  void handleAttendance() {
    setState(() {
      if (!isCheckedIn) {
        isCheckedIn = true;
      } else if (!isCheckedOut) {
        isCheckedOut = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.success,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Office Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Location verification required',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: 'Not Verified',
                        color: AppColors.warning,
                        backgroundColor: AppColors.warningLight,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 170,
                        width: 170,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 5,
                          ),
                        ),
                        child: Icon(
                          isCheckedOut
                              ? Icons.check_circle
                              : isCheckedIn
                                  ? Icons.logout
                                  : Icons.login,
                          color: AppColors.primary,
                          size: 65,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isCheckedOut
                            ? 'Attendance Completed'
                            : isCheckedIn
                                ? 'You are Checked In'
                                : 'Ready to Check In?',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure you are within 200m of office',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isCheckedOut
                              ? null
                              : handleAttendance,
                          icon: Icon(
                            isCheckedIn
                                ? Icons.logout
                                : Icons.login,
                          ),
                          label: Text(
                            isCheckedIn
                                ? 'Check Out'
                                : 'Check In',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.border,
                            disabledForegroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const SectionTitle(title: 'Today Summary'),

                const SizedBox(height: 12),

                AppCard(
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check In Time',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '09:15 AM',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Check Out Time',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            isCheckedOut ? '06:00 PM' : '--:--',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const SectionTitle(title: 'Sync Status'),

                const SizedBox(height: 12),

                const AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        color: AppColors.success,
                        size: 25,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All attendance records are synced',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      StatusChip(
                        label: 'Synced',
                        color: AppColors.success,
                        backgroundColor: AppColors.successLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
