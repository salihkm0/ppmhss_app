import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/models/academic_year_model.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/modal.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/utils/theme.dart';

class AcademicYearSettings extends StatefulWidget {
  const AcademicYearSettings({super.key});

  @override
  State<AcademicYearSettings> createState() => _AcademicYearSettingsState();
}

class _AcademicYearSettingsState extends State<AcademicYearSettings> {
  bool _showForm = false;
  bool _isEditing = false;
  AcademicYearModel? _editingYear;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String? _deleteTargetId;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _loadAcademicYears() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
  }

  void _resetForm() {
    _nameController.clear();
    _yearController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _isEditing = false;
    _editingYear = null;
  }

  void _editYear(AcademicYearModel year) {
    setState(() {
      _isEditing = true;
      _editingYear = year;
      _nameController.text = year.name;
      _yearController.text = year.year;
      _startDateController.text = year.startDate.toIso8601String().split('T')[0];
      _endDateController.text = year.endDate.toIso8601String().split('T')[0];
      _showForm = true;
    });
  }

  void _saveYear() {
    if (!_formKey.currentState!.validate()) return;
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    
    if (_isEditing && _editingYear != null) {
      store.dispatch(updateAcademicYearThunk(UpdateAcademicYearAction(
        id: _editingYear!.id,
        data: {
          'name': _nameController.text,
          'year': _yearController.text,
          'startDate': DateTime.parse(_startDateController.text),
          'endDate': DateTime.parse(_endDateController.text),
        },
      )));
      PopupNotification.showSuccess(context, 'Academic year updated successfully');
    } else {
      store.dispatch(createAcademicYearThunk(CreateAcademicYearAction(data: {
        'name': _nameController.text,
        'year': _yearController.text,
        'startDate': DateTime.parse(_startDateController.text),
        'endDate': DateTime.parse(_endDateController.text),
      })));
      PopupNotification.showSuccess(context, 'Academic year created successfully');
    }
    
    setState(() {
      _showForm = false;
      _resetForm();
    });
    _loadAcademicYears();
  }

  void _setCurrentYear(String id) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(setCurrentAcademicYearThunk(SetCurrentAcademicYearAction(id: id)));
    PopupNotification.showSuccess(context, 'Current academic year set successfully');
    _loadAcademicYears();
  }

  void _confirmDelete(String id) {
    setState(() => _deleteTargetId = id);
  }

  void _deleteYear() {
    if (_deleteTargetId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(deleteAcademicYearThunk(DeleteAcademicYearAction(id: _deleteTargetId!)));
      PopupNotification.showSuccess(context, 'Academic year deleted successfully');
      setState(() => _deleteTargetId = null);
      _loadAcademicYears();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Academic Years',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!_showForm)
                  ElevatedButton.icon(
                    onPressed: () {
                      _resetForm();
                      setState(() => _showForm = true);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Year'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Form
            if (_showForm)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Name', 'e.g., Academic Year 2024-25'),
                      const SizedBox(height: 12),
                      _buildTextField(_yearController, 'Year', 'e.g., 2024-2025'),
                      const SizedBox(height: 12),
                      _buildDateField(_startDateController, 'Start Date'),
                      const SizedBox(height: 12),
                      _buildDateField(_endDateController, 'End Date'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showForm = false;
                                  _resetForm();
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveYear,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_isEditing ? 'Update' : 'Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            // Loading State
            if (state.academicYears.isLoading && state.academicYears.academicYears.isEmpty)
              const LoadingWidget(),
            
            // Academic Years List
            if (!state.academicYears.isLoading || state.academicYears.academicYears.isNotEmpty)
              ...state.academicYears.academicYears.map((year) => _buildYearCard(year)),
            
            if (state.academicYears.academicYears.isEmpty && !state.academicYears.isLoading)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No academic years found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _resetForm();
                        setState(() => _showForm = true);
                      },
                      child: const Text('Add your first academic year →'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: controller.text.isNotEmpty
              ? DateTime.parse(controller.text)
              : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildYearCard(AcademicYearModel year) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: year.isCurrent ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: year.isCurrent ? AppTheme.primaryColor : Colors.grey[200]!,
          width: year.isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      year.year,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (year.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${Formatters.formatDate(year.startDate)} - ${Formatters.formatDate(year.endDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!year.isCurrent)
                TextButton(
                  onPressed: () => _setCurrentYear(year.id),
                  child: const Text('Set as Current'),
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editYear(year),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _confirmDelete(year.id),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}