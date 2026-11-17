
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rebsspace/core/app_colors.dart';
import 'package:rebsspace/core/app_widgets.dart';
import 'package:rebsspace/features/leave/data/models/leave_model.dart';
import 'package:rebsspace/features/leave/presentation/controllers/leave_controller.dart';


class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveController controller = Get.find<LeaveController>();

  final TextEditingController reasonController =
      TextEditingController();

  Future<void> selectDate(bool isStartDate) async {
    final now = DateTime.now();

    final selectedStart = controller.startDate.value;
    final selectedEnd = controller.endDate.value;

    final firstDate = isStartDate
        ? DateTime(now.year, now.month, now.day)
        : selectedStart ?? DateTime(now.year, now.month, now.day);

    final initialDate = isStartDate
        ? (selectedStart != null && !selectedStart.isBefore(firstDate)
            ? selectedStart
            : firstDate)
        : (selectedEnd != null && !selectedEnd.isBefore(firstDate)
            ? selectedEnd
            : firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isStartDate) {
        controller.changeStartDate(picked);
      } else {
        controller.changeEndDate(picked);
      }
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select Date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatHistoryDate(String start, String end) {
    final startDate = DateTime.tryParse(start);
    final endDate = DateTime.tryParse(end);

    if (startDate == null || endDate == null) {
      return '$start - $end';
    }

    final first =
        '${_monthName(startDate.month)} ${startDate.day}';

    if (start == end) return first;

    final last =
        '${_monthName(endDate.month)} ${endDate.day}';

    return '$first - $last';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }

  Future<void> submitRequest() async {
    final success = await controller.submitLeaveRequest(
      reasonController.text,
    );

    if (success && mounted) {
      reasonController.clear();
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Leave Application',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: controller.loadLeaveData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh leave data',
          ),
        ],
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------
                  // OFFLINE STATUS
                  // --------------------------------

                  if (controller.isOffline.value)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You are offline. Showing saved leave data.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --------------------------------
                  // LEAVE BALANCE
                  // --------------------------------

                  AppCard(
                    child: controller.isLoading.value &&
                            controller.leaveRequests.isEmpty &&
                            controller.casualBalance.value == 0 &&
                            controller.sickBalance.value == 0
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                  SizedBox(width: 14),
                                  Text(
                                    'Available Leave Balance',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BalanceItem(
                                      title: 'Casual Leave',
                                      days: controller.casualBalance.value,
                                    ),
                                  ),
                                  Expanded(
                                    child: _BalanceItem(
                                      title: 'Sick Leave',
                                      days: controller.sickBalance.value,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                'Total Available: '
                                '${controller.casualBalance.value + controller.sickBalance.value} Days',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------
                  // LEAVE TYPE
                  // --------------------------------

                  const SectionTitle(title: 'Leave Type'),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: controller.selectedLeaveType.value,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Casual',
                        child: Text('Casual Leave'),
                      ),
                      DropdownMenuItem(
                        value: 'Sick',
                        child: Text('Sick Leave'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.changeLeaveType(value);
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Available ${controller.selectedLeaveType.value} Leave: '
                    '${controller.selectedBalance} Days',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------
                  // SELECT DATES
                  // --------------------------------

                  const SectionTitle(title: 'Select Dates'),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'From Date',
                          date: formatDate(controller.startDate.value),
                          onTap: () => selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'To Date',
                          date: formatDate(controller.endDate.value),
                          onTap: () => selectDate(false),
                        ),
                      ),
                    ],
                  ),

                  if (controller.requestedDays > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Total requested days: ${controller.requestedDays}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --------------------------------
                  // REASON
                  // --------------------------------

                  const SectionTitle(title: 'Reason'),

                  const SizedBox(height: 12),

                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your reason...',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------
                  // SUBMIT BUTTON
                  // --------------------------------

                  PrimaryButton(
                    title: controller.isSubmitting.value
                        ? 'Submitting...'
                        : 'Submit Request',
                    icon: controller.isSubmitting.value
                        ? Icons.hourglass_top
                        : Icons.send,
                    onPressed: controller.isSubmitting.value
                        ? () {}
                        : submitRequest,
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------
                  // LEAVE HISTORY
                  // --------------------------------

                  const SectionTitle(
                    title: 'My Leave Requests',
                  ),

                  const SizedBox(height: 12),

                  if (controller.isLoading.value &&
                      controller.leaveRequests.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (controller.leaveRequests.isEmpty)
                    AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            controller.errorMessage.value.isNotEmpty
                                ? controller.errorMessage.value
                                : 'No leave requests found.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: List.generate(
                          controller.leaveRequests.length,
                          (index) {
                            final request =
                                controller.leaveRequests[index];

                            return Column(
                              children: [
                                _LeaveHistoryTile(
                                  request: request,
                                  date: formatHistoryDate(
                                    request.startDate,
                                    request.endDate,
                                  ),
                                ),
                                if (index !=
                                    controller.leaveRequests.length - 1)
                                  const Divider(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// --------------------------------------------------
// LEAVE BALANCE ITEM
// --------------------------------------------------

class _BalanceItem extends StatelessWidget {
  final String title;
  final int days;

  const _BalanceItem({
    required this.title,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$days Days',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// DATE FIELD
// --------------------------------------------------

class _DateField extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// LEAVE HISTORY TILE
// --------------------------------------------------

class _LeaveHistoryTile extends StatelessWidget {
  final LeaveRequestModel request;
  final String date;

  const _LeaveHistoryTile({
    required this.request,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final status = request.status.toLowerCase();

    Color statusColor;
    Color backgroundColor;

    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        backgroundColor = AppColors.successLight;
        break;

      case 'rejected':
        statusColor = AppColors.error;
        backgroundColor = AppColors.errorLight;
        break;

      default:
        statusColor = AppColors.warning;
        backgroundColor = AppColors.warningLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.event_note,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.leaveType} Leave',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.totalDays} Days',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: request.status,
            color: statusColor,
            backgroundColor: backgroundColor,
          ),
        ],
      ),
    );
  }
}
