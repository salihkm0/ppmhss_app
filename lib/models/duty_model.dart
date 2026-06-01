class DutyModel {
  final String id;
  final String dutyType;
  final DateTime date;
  final String shift;
  final String? location;
  final String? className;
  final String status;
  final String? remarks;

  DutyModel({
    required this.id,
    required this.dutyType,
    required this.date,
    required this.shift,
    this.location,
    this.className,
    this.status = 'assigned',
    this.remarks,
  });

  factory DutyModel.fromJson(Map<String, dynamic> json) {
    return DutyModel(
      id: json['_id'] ?? '',
      dutyType: json['dutyType'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      shift: json['shift'] ?? 'full',
      location: json['location'],
      className: json['className'],
      status: json['status'] ?? 'assigned',
      remarks: json['remarks'],
    );
  }

  String get shiftLabel {
    switch (shift) {
      case 'morning':
        return 'Morning (9:00 AM - 12:00 PM)';
      case 'afternoon':
        return 'Afternoon (2:00 PM - 5:00 PM)';
      default:
        return 'Full Day (9:00 AM - 5:00 PM)';
    }
  }

  String get dutyTypeLabel {
    switch (dutyType) {
      case 'exam':
        return 'Exam';
      case 'invigilation':
        return 'Invigilation';
      case 'supervision':
        return 'Supervision';
      case 'sports':
        return 'Sports';
      default:
        return dutyType.toUpperCase();
    }
  }
}