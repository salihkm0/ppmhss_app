import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/screens/dashboard_screen.dart';
import 'package:school_management/screens/login_screen.dart';
import 'package:school_management/screens/splash_screen.dart';

// Student Screens
import 'package:school_management/screens/students/student_list_screen.dart';
import 'package:school_management/screens/students/student_detail_screen.dart';
import 'package:school_management/screens/students/student_form_screen.dart';

// Attendance Screens
import 'package:school_management/screens/attendance/attendance_screen.dart';
import 'package:school_management/screens/attendance/attendance_detail_screen.dart';

// Duty Screens
import 'package:school_management/screens/duty/duty_list_screen.dart';
import 'package:school_management/screens/duty/duty_detail_screen.dart';

// Notification Screens
import 'package:school_management/screens/notifications/notification_list_screen.dart';
import 'package:school_management/screens/notifications/send_notification_screen.dart';

// Settings Screens
import 'package:school_management/screens/settings/settings_screen.dart';
import 'package:school_management/screens/profile/profile_screen.dart';
import 'package:school_management/screens/support/help_support_screen.dart';

// Class Screens
import 'package:school_management/screens/classes/classes_screen.dart';
import 'package:school_management/screens/classes/class_form_screen.dart';

// Subject Screens
import 'package:school_management/screens/subjects/subjects_screen.dart';
import 'package:school_management/screens/subjects/subject_form_screen.dart';

// Exam Screens
import 'package:school_management/screens/exams/exams_screen.dart';
import 'package:school_management/screens/exams/exam_form_screen.dart';
import 'package:school_management/screens/exams/exam_detail_screen.dart';

// Marks Screens
import 'package:school_management/screens/marks/marks_entry_screen.dart';

// Parent Screens
import 'package:school_management/screens/parent/my_children_page.dart';
import 'package:school_management/screens/parent/my_child_attendance_page.dart';
import 'package:school_management/screens/parent/my_child_results_page.dart';
import 'package:school_management/models/parent_models.dart';

// Staff Screens
import 'package:school_management/screens/staff/my_classes_page.dart';
import 'package:school_management/screens/staff/my_duties_page.dart';
import 'package:school_management/screens/staff/staff_attendance_page.dart';
import 'package:school_management/screens/staff/staff_exams_page.dart';
import 'package:school_management/screens/staff/staff_marks_entry.dart';

// Store
import 'package:school_management/store/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SchoolApp extends StatefulWidget {
  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;

  const SchoolApp({
    super.key,
    required this.prefs,
    required this.secureStorage,
  });

  @override
  State<SchoolApp> createState() => _SchoolAppState();
}

class _SchoolAppState extends State<SchoolApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final token = widget.prefs.getString('token');
    print('🔐 Token found: ${token != null}');
    
    if (token != null && token.isNotEmpty) {
      await StoreProvider.of<AppState>(context, listen: false)
          .dispatch(checkAuthThunk(CheckAuthAction()));
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        StoreProvider.of<AppState>(context, listen: false)
            .dispatch(SetSplashCompleteAction(complete: true));
      }
    }
    
    if (mounted) {
      setState(() => _authChecked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        print('📱 AppState - isLoading: ${state.auth.isLoading}, isAuthenticated: ${state.auth.isAuthenticated}, authChecked: $_authChecked');
        
        // Show splash screen while checking auth or loading
        if (!_authChecked || state.auth.isLoading) {
          return const SplashScreen();
        }
        
        // Show dashboard if authenticated
        if (state.auth.isAuthenticated && state.auth.user != null) {
          return MaterialApp(
            title: 'School Management',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            navigatorKey: _navigatorKey,
            home: const DashboardScreen(),
            onGenerateRoute: _generateRoute,
          );
        }
        
        // Show login screen
        return MaterialApp(
          title: 'School Management',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          navigatorKey: _navigatorKey,
          home: const LoginScreen(),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== STUDENT ROUTES ====================
      case '/students':
        return MaterialPageRoute(
          builder: (_) => const StudentListScreen(),
          settings: settings,
        );
      case '/students/detail':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StudentDetailScreen(studentId: args),
          settings: settings,
        );
      case '/students/add':
        return MaterialPageRoute(
          builder: (_) => const StudentFormScreen(),
          settings: settings,
        );
      case '/students/edit':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StudentFormScreen(studentId: args),
          settings: settings,
        );
      
      // ==================== ATTENDANCE ROUTES ====================
      case '/attendance':
        return MaterialPageRoute(
          builder: (_) => const AttendanceScreen(),
          settings: settings,
        );
      case '/attendance/detail':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => AttendanceDetailScreen(
            studentId: args['studentId']!,
            studentName: args['studentName']!,
          ),
          settings: settings,
        );
      
      // ==================== DUTY ROUTES ====================
      case '/duties':
        return MaterialPageRoute(
          builder: (_) => const DutyListScreen(),
          settings: settings,
        );
      case '/duties/detail':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DutyDetailScreen(dutyId: args),
          settings: settings,
        );
      
      // ==================== NOTIFICATION ROUTES ====================
      case '/notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationListScreen(),
          settings: settings,
        );
      case '/notifications/send':
        return MaterialPageRoute(
          builder: (_) => const SendNotificationScreen(),
          settings: settings,
        );
      
      // ==================== SETTINGS ROUTES ====================
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      
      // ==================== DASHBOARD ====================
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      
      // ==================== CLASS ROUTES ====================
      case '/classes':
        return MaterialPageRoute(
          builder: (_) => const ClassesScreen(),
          settings: settings,
        );
      case '/classes/add':
        return MaterialPageRoute(
          builder: (_) => const ClassFormScreen(),
          settings: settings,
        );
      case '/classes/edit':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ClassFormScreen(classId: args),
          settings: settings,
        );
      
      // ==================== SUBJECT ROUTES ====================
      case '/subjects':
        return MaterialPageRoute(
          builder: (_) => const SubjectsScreen(),
          settings: settings,
        );
      case '/subjects/add':
        return MaterialPageRoute(
          builder: (_) => const SubjectFormScreen(),
          settings: settings,
        );
      case '/subjects/edit':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SubjectFormScreen(subjectId: args),
          settings: settings,
        );
      
      // ==================== EXAM ROUTES ====================
      case '/exams':
        return MaterialPageRoute(
          builder: (_) => const ExamsScreen(),
          settings: settings,
        );
      case '/exams/add':
        return MaterialPageRoute(
          builder: (_) => const ExamFormScreen(),
          settings: settings,
        );
      case '/exams/edit':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ExamFormScreen(examId: args),
          settings: settings,
        );
      case '/exams/detail':
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ExamDetailScreen(examId: args),
          settings: settings,
        );
      
      // ==================== MARKS ROUTES ====================
      case '/marks/entry':
        return MaterialPageRoute(
          builder: (_) => const MarksEntryScreen(),
          settings: settings,
        );
      
      // ==================== PARENT ROUTES ====================
      case '/my-children':
        return MaterialPageRoute(
          builder: (_) => const MyChildrenPage(),
          settings: settings,
        );
      case '/my-child-attendance':
        final child = settings.arguments as StudentChild?;
        if (child != null) {
          return MaterialPageRoute(
            builder: (_) => MyChildAttendancePage(
              studentId: child.id,
              studentName: child.fullName,
              attendanceData: child.attendance,
            ),
            settings: settings,
          );
        }
        
        final args = settings.arguments as Map<String, String>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => MyChildAttendancePage(
              studentId: args['studentId']!,
              studentName: args['studentName']!,
            ),
            settings: settings,
          );
        }
        // If no arguments, just navigate without them (will show error state)
        return MaterialPageRoute(
          builder: (_) => const MyChildAttendancePage(
            studentId: '',
            studentName: '',
          ),
          settings: settings,
        );
      case '/my-child-results':
        final child = settings.arguments as StudentChild?;
        if (child != null) {
          return MaterialPageRoute(
            builder: (_) => MyChildResultsPage(
              studentId: child.id,
              studentName: child.fullName,
              examPerformance: child.examPerformance,
            ),
            settings: settings,
          );
        }
        
        final args = settings.arguments as Map<String, String>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => MyChildResultsPage(
              studentId: args['studentId']!,
              studentName: args['studentName']!,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const MyChildResultsPage(
            studentId: '',
            studentName: '',
          ),
          settings: settings,
        );
      
      // ==================== STAFF ROUTES ====================
      case '/staff/my-classes':
        return MaterialPageRoute(
          builder: (_) => const MyClassesPage(),
          settings: settings,
        );
      case '/staff/my-duties':
        return MaterialPageRoute(
          builder: (_) => const MyDutiesPage(),
          settings: settings,
        );
      case '/staff/attendance':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args.containsKey('classId')) {
          return MaterialPageRoute(
            builder: (_) => StaffAttendancePage(
              classId: args['classId']!,
              className: args['className'] ?? '',
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const StaffAttendancePage(
            classId: '',
            className: '',
          ),
          settings: settings,
        );
      case '/staff/exams':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args.containsKey('classId')) {
          return MaterialPageRoute(
            builder: (_) => StaffExamsPage(
              classId: args['classId']!,
              className: args['className'] ?? '',
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const StaffExamsPage(
            classId: '',
            className: '',
          ),
          settings: settings,
        );
      case '/staff/mark':
        final args = settings.arguments as Map<String, String>?;
        if (args != null && args.containsKey('classId')) {
          return MaterialPageRoute(
            builder: (_) => StaffMarksEntryPage(
              classId: args['classId']!,
              className: args['className'] ?? '',
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const StaffMarksEntryPage(
            classId: '',
            className: '',
          ),
          settings: settings,
        );

      case '/help-support':
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );
      
      default:
        return null;
    }
  }
}