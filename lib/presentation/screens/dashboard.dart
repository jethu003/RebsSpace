
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'REBS HRMS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee details
                AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.secondary,
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jithu Mathew',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'EMP001 • Development',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const SectionTitle(title: "Today's Attendance"),

                const SizedBox(height: 12),

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Checked In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: 'Present',
                            color: AppColors.success,
                            backgroundColor: AppColors.successLight,
                          ),
                        ],
                      ),
                      const Divider(height: 25),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check In',
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
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check Out',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '--:--',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Row(
                  children: [
                    InfoTile(
                      icon: Icons.calendar_month,
                      title: 'Leave Balance',
                      value: '12 Days',
                    ),
                    SizedBox(width: 12),
                    InfoTile(
                      icon: Icons.access_time,
                      title: 'Working Hours',
                      value: '04:30',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const SectionTitle(
                  title: 'Recent Attendance',
                  action: 'View All',
                ),

                const SizedBox(height: 12),

                const AppCard(
                  child: Column(
                    children: [
                      AttendanceHistoryTile(
                        date: 'Nov 16, 2026',
                        time: '09:15 AM',
                        status: 'Present',
                      ),
                      Divider(),
                      AttendanceHistoryTile(
                        date: 'Nov 15, 2026',
                        time: '09:05 AM - 06:00 PM',
                        status: 'Present',
                      ),
                      Divider(),
                      AttendanceHistoryTile(
                        date: 'Nov 14, 2026',
                        time: '09:10 AM - 05:45 PM',
                        status: 'Present',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceHistoryTile extends StatelessWidget {
  final String date;
  final String time;
  final String status;

  const AttendanceHistoryTile({
    super.key,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: status,
            color: AppColors.success,
            backgroundColor: AppColors.successLight,
          ),
        ],
      ),
    );
  }
}
