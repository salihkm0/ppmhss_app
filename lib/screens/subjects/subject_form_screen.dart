import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/subject_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';

class SubjectFormScreen extends StatefulWidget {
  final String? subjectId;
  
  const SubjectFormScreen({super.key, this.subjectId});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _creditHoursController = TextEditingController();
  String _type = 'core';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.subjectId != null;
    if (_isEditing) {
      _loadSubject();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  void _loadSubject() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchSubjectByIdThunk(FetchSubjectByIdAction(id: widget.subjectId!)));
  }

  void _saveSubject() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    final data = {
      'name': _nameController.text,
      'code': _codeController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'type': _type,
      'department': _departmentController.text.isEmpty ? null : _departmentController.text,
      'creditHours': int.tryParse(_creditHoursController.text),
    };
    
    if (_isEditing && widget.subjectId != null) {
      store.dispatch(updateSubjectThunk(UpdateSubjectAction(id: widget.subjectId!, data: data)));
      PopupNotification.showSuccess(context, 'Subject updated successfully');
    } else {
      store.dispatch(createSubjectThunk(CreateSubjectAction(data: data)));
      PopupNotification.showSuccess(context, 'Subject created successfully');
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Subject' : 'Add New Subject',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          // Load subject data if editing
          if (_isEditing && state.subjects.currentSubject != null && _nameController.text.isEmpty) {
            final subject = state.subjects.currentSubject!;
            _nameController.text = subject.name;
            _codeController.text = subject.code;
            _descriptionController.text = subject.description ?? '';
            _type = subject.type;
            _departmentController.text = subject.department ?? '';
            _creditHoursController.text = subject.creditHours?.toString() ?? '';
          }
          
          if (state.subjects.isLoading && _isEditing && state.subjects.currentSubject == null) {
            return const LoadingWidget();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Subject Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name *',
                      hintText: 'e.g., Mathematics',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Subject name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Subject Code
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Subject Code *',
                      hintText: 'e.g., MAT101',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Subject code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Subject Type
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Subject Type',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'core', child: Text('Core')),
                        DropdownMenuItem(value: 'elective', child: Text('Elective')),
                        DropdownMenuItem(value: 'optional', child: Text('Optional')),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Department
                  TextFormField(
                    controller: _departmentController,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      hintText: 'e.g., Sciences, Languages',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Credit Hours
                  TextFormField(
                    controller: _creditHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Credit Hours',
                      hintText: '1-6',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of the subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  CustomButton(
                    text: _isEditing ? 'Update Subject' : 'Create Subject',
                    onPressed: _saveSubject,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}