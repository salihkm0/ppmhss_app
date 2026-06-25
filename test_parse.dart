import 'dart:convert';
import 'lib/models/dashboard_model.dart';

void main() {
  String jsonStr = '''
  {
    "staffInfo": {},
    "quickStats": {},
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
    }
  }
  ''';
  
  try {
    var decoded = jsonDecode(jsonStr);
    var data = StaffDashboardData.fromJson(decoded);
    print('classTeacherInfo is null: ${data.classTeacherInfo == null}');
    if (data.classTeacherInfo != null) {
      print('classes length: ${data.classTeacherInfo!.classes.length}');
      if (data.classTeacherInfo!.classes.isNotEmpty) {
        print('class name: ${data.classTeacherInfo!.classes.first.name}');
      }
    }
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
