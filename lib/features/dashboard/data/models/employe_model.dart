
class EmployeeModel {
  final String employeeName;
  final String employeeId;
  final String department;
  final int leaveBalance;

  EmployeeModel({
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.leaveBalance,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      employeeName: json['employeeName'],
      employeeId: json['employeeId'],
      department: json['department'],
      leaveBalance: json['leaveBalance'],
    );
  }
}
