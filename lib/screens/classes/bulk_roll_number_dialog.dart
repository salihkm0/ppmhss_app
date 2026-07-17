import 'package:flutter/material.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/services/student_service.dart';

class BulkRollNumberDialog extends StatefulWidget {
  final ClassModel classModel;
  final List<StudentModel> students;
  final VoidCallback onSaved;

  const BulkRollNumberDialog({
    super.key,
    required this.classModel,
    required this.students,
    required this.onSaved,
  });

  @override
  State<BulkRollNumberDialog> createState() => _BulkRollNumberDialogState();
}

class _BulkRollNumberDialogState extends State<BulkRollNumberDialog> {
  final StudentService _studentService = StudentService();
  bool _isSaving = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var student in widget.students) {
      _controllers[student.id] = TextEditingController(text: student.rollNumber ?? '');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updates = widget.students.map((s) {
        return {
          'id': s.id,
          'rollNumber': _controllers[s.id]?.text.trim(),
        };
      }).where((update) => update['rollNumber'] != null).toList();

      await _studentService.bulkUpdateRollNumbers(
        classId: widget.classModel.id,
        updates: updates,
      );

      if (mounted) {
        PopupNotification.showSuccess(context, 'Roll numbers updated successfully');
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Roll Numbers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _controllers[student.id],
                          decoration: InputDecoration(
                            hintText: 'Roll No',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: 'Save Roll Numbers',
                onPressed: _save,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
