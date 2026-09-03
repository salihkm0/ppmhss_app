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
  
  String _notificationType = 'info';
  String _recipientType = 'class';
  String _selectedRole = 'parent';
  String? _selectedClassId;
  User? _selectedUser;
  
  bool _isSending = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_recipientType == 'class' && _selectedClassId == null) {
      PopupNotification.showError(context, 'Please select a class');
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
        'recipientType': _recipientType,
      };

      if (_linkController.text.trim().isNotEmpty) {
        payload['link'] = _linkController.text.trim();
      }

      if (_recipientType == 'role') {
        payload['targetRole'] = _selectedRole;
      } else if (_recipientType == 'class') {
        payload['classId'] = _selectedClassId;
      } else if (_recipientType == 'user') {
        payload['recipientId'] = _selectedUser!.id;
      }

      await _notificationService.sendNotification(payload);

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
          final roleOptions = vm.isStaff ? ['parent'] : ['admin', 'staff', 'parent'];

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
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'As a staff member, notifications will be sent strictly to parents of students in your assigned teaching classes.',
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
                  
                  // Recipient Type Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildRecipientTab('Class', 'class'),
                        _buildRecipientTab('Role', 'role'),
                        _buildRecipientTab('Specific User', 'user'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recipient Selection based on type
                  if (_recipientType == 'role') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Target Role',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: roleOptions.map((role) {
                              final isSelected = _selectedRole == role;
                              return FilterChip(
                                label: Text(role.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedRole = role);
                                },
                                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryColor,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_recipientType == 'class') ...[
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
                            labelText: 'Select Target Class',
                            border: InputBorder.none,
                          ),
                          items: vm.availableClasses.map((c) {
                            final label = c.displayName ?? '${c.name}${c.section != null ? ' - ${c.section}' : ''}';
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedClassId = value),
                        ),
                      ),
                    ),
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
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
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
              fontSize: 12,
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