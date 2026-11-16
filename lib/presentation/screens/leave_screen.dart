
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  String leaveType = 'Casual Leave';

  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController reasonController =
      TextEditingController();

  Future<void> selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(picked)) {
            toDate = null;
          }
        } else if (fromDate != null &&
            !picked.isBefore(fromDate!)) {
          toDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select Date';

    return '${date.day}/${date.month}/${date.year}';
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Leave Balance',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '12 Days',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const SectionTitle(title: 'Leave Type'),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: leaveType,
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
                      value: 'Casual Leave',
                      child: Text('Casual Leave'),
                    ),
                    DropdownMenuItem(
                      value: 'Sick Leave',
                      child: Text('Sick Leave'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        leaveType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                const SectionTitle(title: 'Select Dates'),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'From Date',
                        date: formatDate(fromDate),
                        onTap: () => selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'To Date',
                        date: formatDate(toDate),
                        onTap: () => selectDate(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

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

                PrimaryButton(
                  title: 'Submit Request',
                  icon: Icons.send,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'UI only - API integration pending',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const SectionTitle(
                  title: 'My Leave Requests',
                ),

                const SizedBox(height: 12),

                const AppCard(
                  child: Column(
                    children: [
                      _LeaveHistoryTile(
                        type: 'Casual Leave',
                        date: 'Nov 20 - Nov 21',
                        status: 'Pending',
                        statusColor: AppColors.warning,
                        backgroundColor: AppColors.warningLight,
                      ),
                      Divider(),
                      _LeaveHistoryTile(
                        type: 'Sick Leave',
                        date: 'Oct 10 - Oct 11',
                        status: 'Approved',
                        statusColor: AppColors.success,
                        backgroundColor: AppColors.successLight,
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

class _LeaveHistoryTile extends StatelessWidget {
  final String type;
  final String date;
  final String status;
  final Color statusColor;
  final Color backgroundColor;

  const _LeaveHistoryTile({
    required this.type,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
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
                  type,
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
              ],
            ),
          ),
          StatusChip(
            label: status,
            color: statusColor,
            backgroundColor: backgroundColor,
          ),
        ],
      ),
    );
  }
}
