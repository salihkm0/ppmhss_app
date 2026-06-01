import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/utils/validators.dart';
import 'package:school_management/widgets/common/popup_notification.dart';

class StudentFormScreen extends StatefulWidget {
  final String? studentId;
  
  const StudentFormScreen({super.key, this.studentId});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _admissionNoController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _admissionNoController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  void _saveStudent() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      PopupNotification.showSuccess(context, 
        widget.studentId == null ? 'Student added successfully' : 'Student updated successfully');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.studentId == null ? 'Add Student' : 'Edit Student',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _rollNumberController,
                label: 'Roll Number',
                prefixIcon: Icons.numbers,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _admissionNoController,
                label: 'Admission Number',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Parent Information',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _parentNameController,
                label: 'Parent Name',
                prefixIcon: Icons.family_restroom_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _parentPhoneController,
                label: 'Parent Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _parentEmailController,
                label: 'Parent Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.validateEmail(value);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: widget.studentId == null ? 'Add Student' : 'Save Changes',
                onPressed: _saveStudent,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}