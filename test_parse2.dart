import 'dart:convert';
import 'lib/models/dashboard_model.dart';

void main() {
  String jsonStr = '''
{
  "staffInfo": {
    "id": "69e47905ec82992931aa73fd",
    "name": "John Doe",
    "staffCode": "STF260001",
    "role": "teacher",
    "photoUrl": null,
    "email": "teacher1@school.com",
    "phone": "9876543210"
  },
  "quickStats": {
    "classesTaught": 3,
    "subjectsTaught": 1,
    "totalStudents": 49,
    "pendingTasks": 3
  },
  "todaySchedule": [],
  "pendingTasks": [
    {
      "id": "attendance_69e45e3fbebdafc9fa25f366",
      "title": "Mark Attendance",
      "description": "Mark attendance for 10-A",
      "deadline": "Today 4:00 PM",
      "priority": "high",
      "link": "/attendance?classId=69e45e3fbebdafc9fa25f366",
      "type": "attendance"
    }
  ],
  "upcomingDuties": [],
  "recentActivities": [],
  "classTeacherInfo": {
    "classes": [
      {
        "id": "69e45e3fbebdafc9fa25f366",
        "name": "10-A",
        "studentCount": 49
      }
    ],
    "averageAttendance": "79.3",
    "pendingParentRequests": 0,
    "readyReports": []
  },
  "subjectClasses": [
    {
      "id": "69e45e3fbebdafc9fa25f366",
      "name": "10-A",
      "subjects": [
        "Mathematics"
      ]
    },
    {
      "id": "69e45e3fbebdafc9fa25f367",
      "name": "10-B",
      "subjects": [
        "Mathematics"
      ]
    }
  ],
  "academicYear": {
    "id": "69e45b3d1b752fb938c71439",
    "name": "2025-2026",
    "year": "2025-2026"
  }
}
  ''';
  
  try {
    var decoded = jsonDecode(jsonStr);
    var data = StaffDashboardData.fromJson(decoded);
    print('SUCCESS!');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
