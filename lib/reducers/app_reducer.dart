import 'package:redux/redux.dart';
import 'package:school_management/reducers/auth_reducer.dart';
import 'package:school_management/reducers/student_reducer.dart';
import 'package:school_management/reducers/attendance_reducer.dart';
import 'package:school_management/reducers/duty_reducer.dart';
import 'package:school_management/reducers/notification_reducer.dart';
import 'package:school_management/reducers/class_reducer.dart';
import 'package:school_management/reducers/subject_reducer.dart';
import 'package:school_management/reducers/exam_reducer.dart';
import 'package:school_management/reducers/academic_year_reducer.dart';
import 'package:school_management/reducers/socket_reducer.dart';
import 'package:school_management/reducers/dashboard_reducer.dart';
import 'package:school_management/reducers/parent_reducer.dart';
import 'package:school_management/reducers/staff_reducer.dart';
import 'package:school_management/store/app_state.dart';

AppState appReducer(AppState state, dynamic action) {
  return AppState(
    auth: authReducer(state.auth, action),
    students: studentReducer(state.students, action),
    attendance: attendanceReducer(state.attendance, action),
    duties: dutyReducer(state.duties, action),
    notifications: notificationReducer(state.notifications, action),
    classes: classReducer(state.classes, action),
    subjects: subjectReducer(state.subjects, action),
    exams: examReducer(state.exams, action),
    academicYears: academicYearReducer(state.academicYears, action),
    socket: socketReducer(state.socket, action),
    dashboard: dashboardReducer(state.dashboard, action),
    parents: parentReducer(state.parents, action),
    staff: staffReducer(state.staff, action),
  );
}