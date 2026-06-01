import 'package:flutter/material.dart';
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
  String _recipientType = 'role';
  String _selectedRole = 'parent';
  String? _selectedClass;
  User? _selectedUser;
  
  bool _isSending = false;

  final List<String> _classOptions = ['Class 10-A', 'Class 9-B', 'Class 8-C'];
  final List<String> _roleOptions = ['admin', 'staff', 'parent'];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isSending = false);
    PopupNotification.showSuccess(context, 'Notification sent successfully');
    
    // Clear form
    _titleController.clear();
    _messageController.clear();
    _linkController.clear();
    _selectedUser = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Send Notification',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Type
              const Text(
                'Notification Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('Information', 'info', Icons.info_outline),
                  const SizedBox(width: 8),
                  _buildTypeChip('Success', 'success', Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  _buildTypeChip('Warning', 'warning', Icons.warning_amber_outlined),
                  const SizedBox(width: 8),
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
                maxLines: 5,
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
                    _buildRecipientTab('Role', 'role'),
                    _buildRecipientTab('Class', 'class'),
                    _buildRecipientTab('User', 'user'),
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
                        'Select Role',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _roleOptions.map((role) {
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: InputBorder.none,
                    ),
                    items: _classOptions.map((String classOption) {
                      return DropdownMenuItem<String>(
                        value: classOption,
                        child: Text(classOption),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedClass = value),
                  ),
                ),
              ] else ...[
                UserSearchSelect(
                  onSelect: (user) => setState(() => _selectedUser = user),
                  selectedUser: _selectedUser,
                  label: 'Search User',
                  placeholder: 'Search by name or email...',
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Send Button
              CustomButton(
                text: 'Send Notification',
                onPressed: _sendNotification,
                isLoading: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _notificationType == value;
    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
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