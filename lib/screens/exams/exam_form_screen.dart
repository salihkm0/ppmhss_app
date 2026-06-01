import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/subject_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';

class ExamFormScreen extends StatefulWidget {
  final String? examId;
  
  const ExamFormScreen({super.key, this.examId});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  String? _selectedYearId;
  String _examType = 'first';
  String _term = 'first';
  List<String> _selectedClassIds = [];
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = false;
  bool _isEditing = false;
  int _activeTab = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.examId != null;
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
    store.dispatch(fetchClassesThunk(FetchClassesAction(limit: 100)));
    store.dispatch(fetchSubjectsThunk(FetchSubjectsAction(limit: 100)));
    
    if (_isEditing && widget.examId != null) {
      store.dispatch(fetchExamByIdThunk(FetchExamByIdAction(id: widget.examId!)));
    }
  }

  void _addScheduleItem() {
    setState(() {
      _schedule.add({
        'subjectId': null,
        'examDate': null,
        'session': 'BF',
        'maxMarks': 100,
        'passingMarks': 40,
      });
    });
  }

  void _removeScheduleItem(int index) {
    setState(() {
      _schedule.removeAt(index);
    });
  }

  void _saveExam() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassIds.isEmpty) {
      PopupNotification.showError(context, 'Please select at least one class');
      return;
    }
    if (_schedule.isEmpty) {
      PopupNotification.showError(context, 'Please add at least one subject to the schedule');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    final data = {
      'name': _nameController.text,
      'examType': _examType,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'academicYearId': _selectedYearId,
      'term': _term,
      'classIds': _selectedClassIds,
      'startDate': DateTime.parse(_startDateController.text),
      'endDate': DateTime.parse(_endDateController.text),
      'schedule': _schedule.map((s) => {
        'subjectId': s['subjectId'],
        'examDate': DateTime.parse(s['examDate']),
        'session': s['session'],
        'maxMarks': s['maxMarks'],
        'passingMarks': s['passingMarks'],
      }).toList(),
    };
    
    if (_isEditing && widget.examId != null) {
      store.dispatch(updateExamThunk(UpdateExamAction(id: widget.examId!, data: data)));
      PopupNotification.showSuccess(context, 'Exam updated successfully');
    } else {
      store.dispatch(createExamThunk(CreateExamAction(data: data)));
      PopupNotification.showSuccess(context, 'Exam created successfully');
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Examination' : 'Create New Examination'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Classes & Schedule'),
            Tab(text: 'Subjects'),
          ],
        ),
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          // Load exam data if editing
          if (_isEditing && state.exams.currentExam != null && _nameController.text.isEmpty) {
            final exam = state.exams.currentExam!;
            _nameController.text = exam.name;
            _descriptionController.text = exam.description ?? '';
            _examType = exam.examType;
            _term = exam.term;
            _selectedYearId = exam.academicYearId;
            _selectedClassIds = exam.classIds?.map((c) => c.toString()).toList() ?? [];
            _startDateController.text = exam.startDate.toIso8601String().split('T')[0];
            _endDateController.text = exam.endDate.toIso8601String().split('T')[0];
            _schedule = exam.schedule?.map((s) => {
              'subjectId': s.subjectId,
              'examDate': s.examDate.toIso8601String().split('T')[0],
              'session': s.session,
              'maxMarks': s.maxMarks,
              'passingMarks': s.passingMarks,
            }).toList() ?? [];
          }
          
          if (state.exams.isLoading && _isEditing && state.exams.currentExam == null) {
            return const LoadingWidget();
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Basic Info Tab
              _buildBasicInfoTab(state),
              
              // Classes & Schedule Tab
              _buildClassesScheduleTab(state),
              
              // Subjects Tab
              _buildSubjectsTab(state),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: _isEditing ? 'Update Examination' : 'Create Examination',
            onPressed: _saveExam,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Exam Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exam Name *',
                hintText: 'e.g., First Term Examination',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Exam name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Exam Type
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _examType,
                decoration: const InputDecoration(
                  labelText: 'Exam Type *',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'first', child: Text('First Term')),
                  DropdownMenuItem(value: 'second', child: Text('Second Term')),
                  DropdownMenuItem(value: 'final', child: Text('Final Exam')),
                  DropdownMenuItem(value: 'mid', child: Text('Mid Term')),
                  DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                  DropdownMenuItem(value: 'half_yearly', child: Text('Half Yearly')),
                  DropdownMenuItem(value: 'annual', child: Text('Annual')),
                ],
                onChanged: (value) => setState(() => _examType = value!),
              ),
            ),
            const SizedBox(height: 16),
            
            // Term
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _term,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'first', child: Text('First Term')),
                  DropdownMenuItem(value: 'second', child: Text('Second Term')),
                  DropdownMenuItem(value: 'third', child: Text('Third Term')),
                  DropdownMenuItem(value: 'fourth', child: Text('Fourth Term')),
                ],
                onChanged: (value) => setState(() => _term = value!),
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
                  if (value == null || value.isEmpty) return 'Academic year is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Start Date
            _buildDateField(_startDateController, 'Start Date *'),
            const SizedBox(height: 16),
            
            // End Date
            _buildDateField(_endDateController, 'End Date *'),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter a brief description of the examination...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesScheduleTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Class Selection
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Target Classes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Divider(),
                ...state.classes.classes.map((classObj) => CheckboxListTile(
                  title: Text(classObj.displayName ?? classObj.name),
                  value: _selectedClassIds.contains(classObj.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedClassIds.add(classObj.id);
                      } else {
                        _selectedClassIds.remove(classObj.id);
                      }
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                )),
                if (state.classes.classes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No classes available'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Schedule Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Exam Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addScheduleItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Subject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (_schedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No subjects added yet'),
                          SizedBox(height: 4),
                          Text('Click "Add Subject" to create schedule'),
                        ],
                      ),
                    ),
                  )
                else
                  ..._schedule.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Subject ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _removeScheduleItem(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Subject Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: item['subjectId'],
                              hint: const Text('Select Subject'),
                              isExpanded: true,
                              items: state.subjects.subjects.map((subject) {
                                return DropdownMenuItem(
                                  value: subject.id,
                                  child: Text('${subject.name} (${subject.code})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _schedule[index]['subjectId'] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Exam Date
                          _buildScheduleDateField(index, item),
                          const SizedBox(height: 8),
                          // Session, Max Marks, Passing Marks Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: item['session'],
                                    decoration: const InputDecoration(
                                      labelText: 'Session',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'BF', child: Text('Morning (9-12)')),
                                      DropdownMenuItem(value: 'AF', child: Text('Afternoon (2-5)')),
                                      DropdownMenuItem(value: 'FULL', child: Text('Full Day')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _schedule[index]['session'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item['maxMarks'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Max Marks',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (value) {
                                    _schedule[index]['maxMarks'] = int.tryParse(value) ?? 0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item['passingMarks'].toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Passing Marks',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (value) {
                                    _schedule[index]['passingMarks'] = int.tryParse(value) ?? 0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDateField(int index, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: item['examDate'] != null ? DateTime.parse(item['examDate']) : DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _schedule[index]['examDate'] = date.toIso8601String().split('T')[0];
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(text: item['examDate'] ?? ''),
          decoration: InputDecoration(
            labelText: 'Exam Date *',
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Exam date is required';
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSubjectsTab(AppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Subjects are configured in the schedule',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects in the Schedule tab above',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          controller.text = date.toIso8601String().split('T')[0];
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '$label is required';
            return null;
          },
        ),
      ),
    );
  }
}