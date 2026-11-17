
class LeaveRequestModel {
  final String requestId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final int totalDays;
  final String status;
  final String? createdAt;

  LeaveRequestModel({
    required this.requestId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.totalDays,
    required this.status,
    this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      requestId: (json['id'] ?? json['requestId'] ?? '').toString(),
      leaveType: json['leaveType'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      reason: json['reason'] ?? '',
      totalDays: (json['requestedDays'] ?? json['totalDays'] ?? 0) as int,
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'],
    );
  }

  // Format used by our SQLite cache.
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      'totalDays': totalDays,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
