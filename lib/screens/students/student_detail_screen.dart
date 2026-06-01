// import 'package:flutter/material.dart';
// import 'package:flutter_redux/flutter_redux.dart';
// import 'package:school_management/actions/student_actions.dart';
// import 'package:school_management/store/app_state.dart';
// import 'package:school_management/widgets/common/custom_appbar.dart';
// import 'package:school_management/widgets/common/loading_widget.dart';
// import 'package:school_management/utils/theme.dart';
// import 'package:school_management/utils/formatters.dart';

// class StudentDetailScreen extends StatefulWidget {
//   final String studentId;
  
//   const StudentDetailScreen({super.key, required this.studentId});

//   @override
//   State<StudentDetailScreen> createState() => _StudentDetailScreenState();
// }

// class _StudentDetailScreenState extends State<StudentDetailScreen> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _loadStudent();
//   }

//   void _loadStudent() {
//     final store = StoreProvider.of<AppState>(context, listen: false);
//     store.dispatch(FetchStudentByIdAction(id: widget.studentId));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: 'Student Details',
//         showBackButton: true,
//       ),
//       body: StoreConnector<AppState, AppState>(
//         converter: (store) => store.state,
//         onWillChange: (previous, next) {
//           if (next.students.error != null && previous?.students.error != next.students.error) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(next.students.error!)),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state.students.isLoading && state.students.currentStudent == null) {
//             return const LoadingWidget();
//           }

//           if (state.students.currentStudent == null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Student not found',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final student = state.students.currentStudent!;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Profile Header
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryColor.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Center(
//                           child: Text(
//                             Formatters.getInitials(student.fullName),
//                             style: TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.bold,
//                               color: AppTheme.primaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         student.fullName,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Student Code: ${student.studentCode}',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Info Cards
//                 _buildInfoCard(
//                   title: 'Academic Information',
//                   icon: Icons.school_outlined,
//                   children: [
//                     _buildInfoRow('Class', student.className ?? 'N/A'),
//                     _buildInfoRow('Roll Number', student.rollNumber ?? 'N/A'),
//                     _buildInfoRow('Admission No', student.admissionNo ?? 'N/A'),
//                     _buildInfoRow('Status', student.status),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 _buildInfoCard(
//                   title: 'Personal Information',
//                   icon: Icons.person_outline,
//                   children: [
//                     _buildInfoRow('Gender', student.gender ?? 'N/A'),
//                     _buildInfoRow(
//                       'Date of Birth',
//                       student.dateOfBirth != null
//                           ? Formatters.formatDate(student.dateOfBirth)
//                           : 'N/A',
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 _buildInfoCard(
//                   title: 'Parent Information',
//                   icon: Icons.family_restroom_outlined,
//                   children: [
//                     _buildInfoRow('Parent Name', student.parentName ?? 'N/A'),
//                     _buildInfoRow('Phone', student.parentPhone ?? 'N/A'),
//                     _buildInfoRow('Email', student.parentEmail ?? 'N/A'),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildInfoCard({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Icon(icon, size: 20, color: AppTheme.primaryColor),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(children: children),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/utils/formatters.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStudent();
  }

  void _loadStudent() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(FetchStudentByIdAction(id: widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Student Details',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          if (state.students.isLoading && state.students.currentStudent == null) {
            return const LoadingWidget();
          }

          if (state.students.currentStudent == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Student not found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final student = state.students.currentStudent!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            Formatters.getInitials(student.fullName),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student Code: ${student.studentCode}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Info Cards
                _buildInfoCard(
                  title: 'Academic Information',
                  icon: Icons.school_outlined,
                  children: [
                    _buildInfoRow('Class', student.className ?? 'N/A'),
                    _buildInfoRow('Roll Number', student.rollNumber ?? 'N/A'),
                    _buildInfoRow('Admission No', student.admissionNo ?? 'N/A'),
                    _buildInfoRow('Status', student.status),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoRow('Gender', student.gender ?? 'N/A'),
                    _buildInfoRow(
                      'Date of Birth',
                      student.dateOfBirth != null
                          ? Formatters.formatDate(student.dateOfBirth)
                          : 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: 'Parent Information',
                  icon: Icons.family_restroom_outlined,
                  children: [
                    _buildInfoRow('Parent Name', student.parentName ?? 'N/A'),
                    _buildInfoRow('Phone', student.parentPhone ?? 'N/A'),
                    _buildInfoRow('Email', student.parentEmail ?? 'N/A'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}