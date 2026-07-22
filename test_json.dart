import 'dart:convert';

void main() {
  String jsonStr = '''
  {
    "tc": {
      "name": "10 - E",
      "subjectTeachers": [
        {
          "subjectId": "6a566e31f8c9c848fb6217bd",
          "teacherId": "6a449ee06848050fa427333f"
        }
      ]
    },
    "exam": {
      "subjects": [
        {
          "subjectId": {
            "_id": "6a566e31f8c9c848fb6217bd",
            "name": "MATHS"
          }
        }
      ]
    }
  }
  ''';
  
  Map<String, dynamic> data = jsonDecode(jsonStr);
  
  final tc = data['tc'];
  final exam = data['exam'];
  final currentStaffId = "6a449ee06848050fa427333f";
  
  final theirSubjects = (tc['subjectTeachers'] as List).where((st) {
    final tId = (st['teacherId'] is Map) ? st['teacherId']['_id'] : st['teacherId'];
    return tId == currentStaffId;
  }).map((e) => (e['subjectId'] is Map) ? e['subjectId']['_id'] : e['subjectId']).toList();
  
  final examSubjectIds = (exam['subjects'] as List).map((s) {
    final sId = (s is Map) ? s['subjectId'] : s;
    return (sId is Map) ? sId['_id'] : sId;
  }).toList();
  
  print('theirSubjects: ' + theirSubjects.toString());
  print('examSubjectIds: ' + examSubjectIds.toString());
  
  final hasMatchingSubject = theirSubjects.any((tsId) => examSubjectIds.contains(tsId));
  print('hasMatchingSubject: ' + hasMatchingSubject.toString());
}
