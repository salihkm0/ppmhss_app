import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/models/student_model.dart';
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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadStudent();
    }
  }

  void _loadStudent() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchStudentByIdThunk(FetchStudentByIdAction(id: widget.studentId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Student Details',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          final isCurrentStudent = state.students.currentStudent?.id == widget.studentId;
          final isLoading = state.students.isLoading && !isCurrentStudent;

          if (isLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state.students.error != null && !isCurrentStudent) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.students.error ?? 'Failed to load student details',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadStudent,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!isCurrentStudent || state.students.currentStudent == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Student not found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final student = state.students.currentStudent!;

          return RefreshIndicator(
            onRefresh: () async => _loadStudent(),
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(student),
                  const SizedBox(height: 16),

                  // Academic Information
                  _buildInfoCard(
                    title: 'Academic Information',
                    icon: Icons.school_outlined,
                    children: [
                      _buildInfoRow('Class', student.className ?? 'N/A'),
                      if (student.division != null && student.division!.isNotEmpty)
                        _buildInfoRow('Division', student.division!),
                      _buildInfoRow('Roll Number', student.rollNumber ?? 'N/A'),
                      _buildInfoRow('Admission No', student.admissionNo ?? 'N/A'),
                      _buildInfoRow('Register / Code', student.studentCode.isNotEmpty ? student.studentCode : 'N/A'),
                      _buildInfoRow('Status', student.status.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Personal Information
                  _buildInfoCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      if (student.fullNameMalayalam != null && student.fullNameMalayalam!.isNotEmpty)
                        _buildInfoRow('Malayalam Name', student.fullNameMalayalam!),
                      _buildInfoRow('Gender', student.gender != null ? student.gender!.toUpperCase() : 'N/A'),
                      _buildInfoRow(
                        'Date of Birth',
                        student.dateOfBirth != null
                            ? Formatters.formatDate(student.dateOfBirth)
                            : 'N/A',
                      ),
                      if (student.bloodGroup != null && student.bloodGroup!.isNotEmpty)
                        _buildInfoRow('Blood Group', student.bloodGroup!),
                      if (student.religion != null && student.religion!.isNotEmpty)
                        _buildInfoRow('Religion', student.religion!),
                      if (student.casteName != null && student.casteName!.isNotEmpty)
                        _buildInfoRow('Caste', student.casteName!),
                      if (student.category != null && student.category!.isNotEmpty)
                        _buildInfoRow('Category', student.category!),
                      if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty)
                        _buildInfoRow('Student Phone', student.phoneNumber!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Parent / Guardian Information
                  _buildInfoCard(
                    title: 'Parent & Guardian Details',
                    icon: Icons.family_restroom_outlined,
                    children: [
                      _buildInfoRow(
                        'Parent / Guardian',
                        student.parentName ?? student.fatherFullName ?? student.guardian ?? 'N/A',
                      ),
                      if (student.motherFullName != null && student.motherFullName!.isNotEmpty)
                        _buildInfoRow('Mother Name', student.motherFullName!),
                      if (student.relationOfGuardian != null && student.relationOfGuardian!.isNotEmpty)
                        _buildInfoRow('Relation', student.relationOfGuardian!),
                      _buildInfoRow('Parent Phone', student.parentPhone ?? 'N/A'),
                      if (student.parentEmail != null && student.parentEmail!.isNotEmpty)
                        _buildInfoRow('Parent Email', student.parentEmail!),
                    ],
                  ),

                  // Address Information (if any available)
                  if (_hasAddressInfo(student)) ...[
                    const SizedBox(height: 14),
                    _buildInfoCard(
                      title: 'Address Information',
                      icon: Icons.home_outlined,
                      children: [
                        if (student.houseName != null && student.houseName!.isNotEmpty)
                          _buildInfoRow('House Name', student.houseName!),
                        if (student.streetName != null && student.streetName!.isNotEmpty)
                          _buildInfoRow('Street', student.streetName!),
                        if (student.postOffice != null && student.postOffice!.isNotEmpty)
                          _buildInfoRow('Post Office', student.postOffice!),
                        if (student.pincode != null && student.pincode!.isNotEmpty)
                          _buildInfoRow('Pincode', student.pincode!),
                        if (student.revenueDistrict != null && student.revenueDistrict!.isNotEmpty)
                          _buildInfoRow('District', student.revenueDistrict!),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasAddressInfo(StudentModel s) {
    return (s.houseName?.isNotEmpty == true) ||
        (s.streetName?.isNotEmpty == true) ||
        (s.postOffice?.isNotEmpty == true) ||
        (s.pincode?.isNotEmpty == true) ||
        (s.revenueDistrict?.isNotEmpty == true);
  }

  Widget _buildProfileHeader(StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                  AppTheme.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                Formatters.getInitials(student.fullName),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (student.fullNameMalayalam != null && student.fullNameMalayalam!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              student.fullNameMalayalam!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (student.className != null && student.className!.isNotEmpty)
                _buildChip(
                  icon: Icons.school_outlined,
                  text: '${student.className}${student.division != null ? ' - ${student.division}' : ''}',
                  color: AppTheme.primaryColor,
                  bg: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                _buildChip(
                  icon: Icons.format_list_numbered,
                  text: 'Roll #${student.rollNumber}',
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                ),
              _buildChip(
                icon: Icons.tag,
                text: 'Reg: ${student.studentCode}',
                color: const Color(0xFF475569),
                bg: const Color(0xFFF1F5F9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}