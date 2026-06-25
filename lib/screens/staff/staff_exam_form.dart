import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/actions/subject_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/models/subject_model.dart';
import 'package:school_management/models/academic_year_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';

class StaffExamFormPage extends StatefulWidget {
  final String classId;
  final String className;
  final ExamModel? existingExam;

  const StaffExamFormPage({
    super.key,
    required this.classId,
    required this.className,
    this.existingExam,
  });

  @override
  State<StaffExamFormPage> createState() => _StaffExamFormPageState();
}

class _StaffExamFormPageState extends State<StaffExamFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _examType = 'custom';
  String _term = 'first';
  String _description = '';
  List<Map<String, dynamic>> _scheduleItems = [];

  bool _isSaving = false;

  final List<String> _examTypes = [
    'unit_test_1',
    'unit_test_2',
    'first_mid_term',
    'first_term',
    'second_mid_term',
    'second_term',
    'model',
    'annual',
    'custom'
  ];

  final List<String> _terms = ['first', 'second', 'third', 'fourth'];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.existingExam != null) {
      final e = widget.existingExam!;
      _name = e.displayName ?? e.name;
      _examType = e.examType;
      _term = e.term;
      _description = e.description ?? '';

      if (e.schedule != null) {
        for (var s in e.schedule!) {
          _scheduleItems.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString() + _scheduleItems.length.toString(),
            'subjectId': s['subjectId'] is Map ? s['subjectId']['_id'] : s['subjectId'],
            'examDate': s['examDate'] != null ? DateTime.parse(s['examDate']) : DateTime.now(),
            'session': s['session'] ?? 'BF',
            'maxMarks': s['maxMarks'] ?? 100,
            'passingMarks': s['passingMarks'] ?? 40,
            'practicalMarks': s['practicalMarks'] ?? 0,
            'ceMaxMarks': s['ceMaxMarks'] ?? 0,
          });
        }
      }
    }
  }

  Future<void> _loadData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchSubjectsThunk(FetchSubjectsAction(limit: 100)));
    await store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 10)));
  }

  void _addScheduleItem() {
    setState(() {
      _scheduleItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'subjectId': null,
        'examDate': DateTime.now(),
        'session': 'BF',
        'maxMarks': 100,
        'passingMarks': 40,
        'practicalMarks': 0,
        'ceMaxMarks': 0,
      });
    });
  }

  void _removeScheduleItem(int index) {
    setState(() {
      _scheduleItems.removeAt(index);
    });
  }

  Future<void> _saveExam(AcademicYearModel? currentYear) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_scheduleItems.isEmpty) {
      _showError('Please add at least one subject to the schedule.');
      return;
    }

    for (var item in _scheduleItems) {
      if (item['subjectId'] == null) {
        _showError('Please select a subject for all schedule items.');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final store = StoreProvider.of<AppState>(context, listen: false);
      
      final examData = {
        'name': _name,
        'examType': _examType,
        'description': _description,
        'academicYearId': currentYear?.id,
        'term': _term,
        'classIds': [widget.classId],
        'schedulingMode': 'subject_schedule',
        'schedule': _scheduleItems.map((item) => {
          'subjectId': item['subjectId'],
          'examDate': item['examDate'].toIso8601String(),
          'session': item['session'],
          'maxMarks': item['maxMarks'],
          'passingMarks': item['passingMarks'],
          'practicalMarks': item['practicalMarks'],
          'ceEnabled': (item['ceMaxMarks'] ?? 0) > 0,
          'ceMaxMarks': item['ceMaxMarks'] ?? 0,
          'cePassingMarks': 0,
          'ceComponents': []
        }).toList()
      };

      if (widget.existingExam != null) {
        await store.dispatch(updateExamThunk(UpdateExamAction(id: widget.existingExam!.id, data: examData)));
      } else {
        await store.dispatch(createExamThunk(CreateExamAction(data: examData)));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingExam != null ? 'Exam updated successfully' : 'Exam created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _formatDisplayType(String str) {
    return str.split('_').map((w) => w.length > 0 ? '\${w[0].toUpperCase()}\${w.substring(1)}' : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.existingExam != null ? 'Edit Exam' : 'Create Exam'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StoreConnector<AppState, _FormViewModel>(
        converter: (store) => _FormViewModel(
          subjects: store.state.subjects.subjects,
          currentYear: store.state.academicYears.currentAcademicYear,
        ),
        builder: (context, vm) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildScheduleSection(vm.subjects),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveExam(vm.currentYear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const LoadingWidget(size: 24)
                        : Text(
                            widget.existingExam != null ? 'Update Exam' : 'Create Exam',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _name,
            decoration: InputDecoration(
              labelText: 'Exam Name *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            onSaved: (v) => _name = v ?? '',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _examType,
                  decoration: InputDecoration(
                    labelText: 'Exam Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _examTypes.map((t) => DropdownMenuItem(value: t, child: Text(_formatDisplayType(t)))).toList(),
                  onChanged: (v) => setState(() => _examType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _term,
                  decoration: InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _terms.map((t) => DropdownMenuItem(value: t, child: Text(_formatDisplayType(t)))).toList(),
                  onChanged: (v) => setState(() => _term = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _description,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 2,
            onSaved: (v) => _description = v ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(List<SubjectModel> subjects) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subjects Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _addScheduleItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Subject'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_scheduleItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No subjects added yet', style: TextStyle(color: Colors.grey[500])),
              ),
            ),
          ..._scheduleItems.asMap().entries.map((e) => _buildScheduleItemCard(e.key, e.value, subjects)).toList()
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(int index, Map<String, dynamic> item, List<SubjectModel> subjects) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subject \${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _removeScheduleItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: item['subjectId'],
            decoration: InputDecoration(
              labelText: 'Subject *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => item['subjectId'] = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: item['examDate'],
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => item['examDate'] = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Exam Date *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(item['examDate'])),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: item['session'],
                  decoration: InputDecoration(
                    labelText: 'Session',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BF', child: Text('Morning')),
                    DropdownMenuItem(value: 'AF', child: Text('Afternoon')),
                    DropdownMenuItem(value: 'FULL', child: Text('Full Day')),
                  ],
                  onChanged: (v) => setState(() => item['session'] = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item['maxMarks'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Max Marks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => item['maxMarks'] = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item['passingMarks'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Pass Marks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => item['passingMarks'] = int.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item['practicalMarks'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Practical',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => item['practicalMarks'] = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item['ceMaxMarks'].toString(),
                  decoration: InputDecoration(
                    labelText: 'CE Marks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => item['ceMaxMarks'] = int.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormViewModel {
  final List<SubjectModel> subjects;
  final AcademicYearModel? currentYear;

  _FormViewModel({
    required this.subjects,
    required this.currentYear,
  });
}
