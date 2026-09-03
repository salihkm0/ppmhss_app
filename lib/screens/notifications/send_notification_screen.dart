import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/services/notification_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/widgets/common/user_search_select.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/utils/theme.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _linkController = TextEditingController();
  final _parentSearchController = TextEditingController();
  
  String _notificationType = 'info';
  String _recipientType = 'class'; // 'class' or 'user'
  String? _selectedClassId;
  User? _selectedUser;
  
  // Class Parents selection state
  String _sendMode = 'all'; // 'all' or 'selected'
  List<Map<String, dynamic>> _classParents = [];
  final Set<String> _selectedParentIds = {};
  bool _isLoadingParents = false;
  String _parentSearchQuery = '';

  bool _isSending = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _parentSearchController.addListener(() {
      setState(() => _parentSearchQuery = _parentSearchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    _parentSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassParents(String classId) async {
    setState(() {
      _isLoadingParents = true;
      _classParents = [];
      _selectedParentIds.clear();
    });

    try {
      final parents = await _notificationService.getClassParents(classId);
      if (mounted) {
        setState(() {
          _classParents = parents;
          for (final p in parents) {
            final id = p['_id']?.toString() ?? p['id']?.toString();
            if (id != null && id.isNotEmpty) {
              _selectedParentIds.add(id);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Failed to fetch class parents: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingParents = false);
      }
    }
  }

  void _onClassSelected(String? classId) {
    if (classId == null || classId == _selectedClassId) return;
    setState(() {
      _selectedClassId = classId;
    });
    _fetchClassParents(classId);
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_recipientType == 'class' && _selectedClassId == null) {
      PopupNotification.showError(context, 'Please select a class');
      return;
    }

    if (_recipientType == 'class' && _sendMode == 'selected' && _selectedParentIds.isEmpty) {
      PopupNotification.showError(context, 'Please select at least one parent');
      return;
    }

    if (_recipientType == 'user' && _selectedUser == null) {
      PopupNotification.showError(context, 'Please select a recipient');
      return;
    }

    setState(() => _isSending = true);
    
    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _notificationType,
      };

      if (_linkController.text.trim().isNotEmpty) {
        payload['link'] = _linkController.text.trim();
      }

      if (_recipientType == 'class') {
        if (_sendMode == 'all') {
          await _notificationService.sendToClass(_selectedClassId!, payload);
        } else {
          // Send to each selected parent
          for (final parentId in _selectedParentIds) {
            await _notificationService.sendToUser(parentId, payload);
          }
        }
      } else if (_recipientType == 'user') {
        await _notificationService.sendToUser(_selectedUser!.id, payload);
      }

      if (mounted) {
        PopupNotification.showSuccess(context, 'Notification sent successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Failed to send notification: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Send Notification',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, _SendNotificationVM>(
        converter: (store) {
          final isStaff = store.state.auth.user?.role == 'staff';
          final availableClasses = isStaff
              ? store.state.classes.teacherClasses
              : store.state.classes.classes;
          return _SendNotificationVM(
            isStaff: isStaff,
            role: store.state.auth.user?.role ?? 'parent',
            availableClasses: availableClasses,
          );
        },
        builder: (context, vm) {
          final filteredParents = _classParents.where((p) {
            if (_parentSearchQuery.isEmpty) return true;
            final pName = (p['name'] ?? '').toString().toLowerCase();
            final pEmail = (p['email'] ?? '').toString().toLowerCase();
            final sNames = (p['studentNames'] as List? ?? []).join(' ').toLowerCase();
            return pName.contains(_parentSearchQuery) ||
                pEmail.contains(_parentSearchQuery) ||
                sNames.contains(_parentSearchQuery);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.isStaff) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'As a staff member, you can send notifications to parents of students in your assigned classes.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notification Type
                  const Text(
                    'Notification Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTypeChip('Information', 'info', Icons.info_outline),
                      _buildTypeChip('Success', 'success', Icons.check_circle_outline),
                      _buildTypeChip('Warning', 'warning', Icons.warning_amber_outlined),
                      _buildTypeChip('Error', 'error', Icons.error_outline),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  CustomTextField(
                    controller: _titleController,
                    label: 'Title',
                    prefixIcon: Icons.title,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Type your message here...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Message is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Link (Optional)
                  CustomTextField(
                    controller: _linkController,
                    label: 'Link (Optional)',
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Recipient Section
                  const Text(
                    'Send To',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  
                  // Recipient Type Tabs (Class Parents vs Specific User)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildRecipientTab('Class Parents', 'class'),
                        _buildRecipientTab('Specific User', 'user'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recipient Selection based on type
                  if (_recipientType == 'class') ...[
                    // Select Class Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Select Class',
                            border: InputBorder.none,
                          ),
                          items: vm.availableClasses.map((c) {
                            final label = c.displayName ?? '${c.name}${c.section != null ? ' - ${c.section}' : ''}';
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: _onClassSelected,
                        ),
                      ),
                    ),
                    
                    if (_selectedClassId != null) ...[
                      const SizedBox(height: 16),
                      // Send Mode Radio Buttons (All vs Selected Parents)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.groups_outlined, size: 16),
                                  SizedBox(width: 6),
                                  Text('All Parents'),
                                ],
                              ),
                              selected: _sendMode == 'all',
                              onSelected: (val) {
                                if (val) setState(() => _sendMode = 'all');
                              },
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: _sendMode == 'all' ? AppTheme.primaryColor : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.checklist_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text('Selected Parents'),
                                ],
                              ),
                              selected: _sendMode == 'selected',
                              onSelected: (val) {
                                if (val) setState(() => _sendMode = 'selected');
                              },
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: _sendMode == 'selected' ? AppTheme.primaryColor : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_isLoadingParents)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: LoadingWidget(),
                        )
                      else if (_sendMode == 'selected') ...[
                        // Search parents / students
                        TextField(
                          controller: _parentSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search parent or student name...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Select All / Deselect All header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected: ${_selectedParentIds.length} / ${_classParents.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedParentIds.length == _classParents.length) {
                                    _selectedParentIds.clear();
                                  } else {
                                    for (final p in _classParents) {
                                      final id = (p['_id'] ?? p['id'] ?? p['key'])?.toString();
                                      if (id != null) _selectedParentIds.add(id);
                                    }
                                  }
                                });
                              },
                              child: Text(
                                _selectedParentIds.length == _classParents.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Parents List with Student Name Badges
                        if (filteredParents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('No parents found for this class',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredParents.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, index) {
                                final p = filteredParents[index];
                                final parentId = (p['_id'] ?? p['id'] ?? p['key'])?.toString() ?? '';
                                final parentName = (p['name'] ?? 'Parent').toString();
                                final studentNamesList = (p['studentNames'] as List? ?? []);
                                final studentNamesText = studentNamesList.join(', ');
                                final isChecked = _selectedParentIds.contains(parentId);

                                return CheckboxListTile(
                                  value: isChecked,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedParentIds.add(parentId);
                                      } else {
                                        _selectedParentIds.remove(parentId);
                                      }
                                    });
                                  },
                                  title: Text(
                                    parentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (studentNamesText.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Student: $studentNamesText',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if ((p['phone'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          p['phone'].toString(),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ] else ...[
                    UserSearchSelect(
                      onSelect: (user) => setState(() => _selectedUser = user),
                      selectedUser: _selectedUser,
                      label: vm.isStaff ? 'Search Parent' : 'Search User',
                      placeholder: vm.isStaff ? 'Search parent by name or email...' : 'Search user by name or email...',
                    ),
                  ],
                  
                  // Send Button with full width and bottom padding
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 60),
                    child: CustomButton(
                      text: 'Send Notification',
                      isFullWidth: true,
                      icon: Icons.send_rounded,
                      onPressed: _sendNotification,
                      isLoading: _isSending,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _notificationType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _notificationType = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildRecipientTab(String label, String value) {
    final isSelected = _recipientType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _recipientType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendNotificationVM {
  final bool isStaff;
  final String role;
  final List<ClassModel> availableClasses;

  _SendNotificationVM({
    required this.isStaff,
    required this.role,
    required this.availableClasses,
  });
}