import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';

class ClassFormScreen extends StatefulWidget {
  final String? classId;
  
  const ClassFormScreen({super.key, this.classId});

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _selectedYearId;
  String _studentSortPreference = 'alphabetic';
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.classId != null;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _loadData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
    
    if (_isEditing && widget.classId != null) {
      store.dispatch(fetchClassByIdThunk(FetchClassByIdAction(id: widget.classId!)));
    }
  }

  void _saveClass() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    final data = {
      'name': _nameController.text,
      'section': _sectionController.text.isEmpty ? null : _sectionController.text,
      'capacity': int.tryParse(_capacityController.text),
      'academicYearId': _selectedYearId,
      'studentSortPreference': _studentSortPreference,
    };
    
    if (_isEditing && widget.classId != null) {
      store.dispatch(updateClassThunk(UpdateClassAction(id: widget.classId!, data: data)));
      PopupNotification.showSuccess(context, 'Class updated successfully');
    } else {
      store.dispatch(createClassThunk(CreateClassAction(data: data)));
      PopupNotification.showSuccess(context, 'Class created successfully');
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
        title: _isEditing ? 'Edit Class' : 'Add New Class',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          // Load class data if editing and not already loaded
          if (_isEditing && state.classes.currentClass != null && _nameController.text.isEmpty) {
            final classObj = state.classes.currentClass!;
            _nameController.text = classObj.name;
            _sectionController.text = classObj.section ?? '';
            _capacityController.text = classObj.capacity?.toString() ?? '';
            _selectedYearId = classObj.academicYearId;
            if (classObj.studentSortPreference != null) {
              _studentSortPreference = classObj.studentSortPreference!;
            }
          }
          
          if (state.classes.isLoading && _isEditing && state.classes.currentClass == null) {
            return const LoadingWidget();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Class Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name *',
                      hintText: 'e.g., 10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Class name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Section
                  TextFormField(
                    controller: _sectionController,
                    decoration: InputDecoration(
                      labelText: 'Section',
                      hintText: 'e.g., A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Capacity
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Maximum students',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Academic Year
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedYearId,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Select Academic Year *'),
                      ),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: state.academicYears.academicYears.map((year) {
                        return DropdownMenuItem(
                          value: year.id,
                          child: Text(year.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedYearId = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Academic year is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Student Sort Preference
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _studentSortPreference,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        labelText: 'Student Sort Order',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'alphabetic',
                          child: Text('Alphabetical (Girls first, then Boys)'),
                        ),
                        DropdownMenuItem(
                          value: 'roll_number',
                          child: Text('Roll Number (Numeric)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _studentSortPreference = value);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  CustomButton(
                    text: _isEditing ? 'Update Class' : 'Create Class',
                    onPressed: _saveClass,
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