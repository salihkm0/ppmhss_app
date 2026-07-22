import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/actions/dashboard_actions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isUpdating = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });
      
      try {
        await AuthService().updateProfile({
          'name': _nameController.text.trim(),
        });
        
        if (mounted) {
          // Update Redux state
          final store = StoreProvider.of<AppState>(context, listen: false);
          store.dispatch(getMeThunk(GetMeAction()));
          
          // Refresh dashboard data as well so name/phone updates everywhere
          final role = store.state.auth.user?.role;
          if (role == 'staff') {
            store.dispatch(fetchStaffDashboardThunk());
          } else if (role == 'parent') {
            store.dispatch(fetchParentDashboardThunk());
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
          );
          setState(() {
            _isEditing = false;
            _isUpdating = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      obscureText: true,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: newPasswordController,
                      label: 'New Password',
                      obscureText: true,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSubmitting = true);
                            try {
                              await AuthService().changePassword(
                                currentPassword: currentPasswordController.text,
                                newPassword: newPasswordController.text,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Change', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          final user = state.auth.user;
          
          if (user == null) {
            return const Scaffold(
              body: Center(
                child: Text('No user data available'),
              ),
            );
          }
          
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
            _emailController.text = user.email ?? '';
            _phoneController.text = user.phone ?? '';
          }

          return Scaffold(
            appBar: const CustomAppBar(
              title: 'Profile',
              showBackButton: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Profile Avatar
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Role Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Profile Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                prefixIcon: Icons.person_outline,
                                readOnly: !_isEditing,
                                validator: _isEditing ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name is required';
                                  }
                                  return null;
                                } : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                readOnly: true,
                                hint: 'Not provided',
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                prefixIcon: Icons.phone_android_outlined,
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoTile('Member Since', 
                                user.createdAt != null 
                                  ? DateFormat('MMMM d, yyyy').format(user.createdAt!)
                                  : 'N/A'),
                      const SizedBox(height: 16),
                      _buildInfoTile('User ID', user.id),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_isEditing)
                  Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isUpdating ? null : () {
                                    setState(() {
                                      _isEditing = false;
                                      if (user != null) {
                                        _nameController.text = user.name;
                                        _emailController.text = user.email ?? '';
                                        _phoneController.text = user.phone ?? '';
                                      }
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: _isUpdating ? 'Saving...' : 'Save Changes',
                                  onPressed: _isUpdating ? null : _updateProfile,
                                  isLoading: _isUpdating,
                                ),
                              ),
                            ],
                  ),
                
                if (!_isEditing)
                  CustomButton(
                    text: 'Edit Profile',
                    onPressed: () => setState(() => _isEditing = true),
                    icon: Icons.edit_outlined,
                    isFullWidth: true,
                  ),
                
                const SizedBox(height: 16),
                
                // Change Password Button
                CustomButton(
                  text: 'Change Password',
                  onPressed: _showChangePasswordDialog,
                  icon: Icons.lock_outline,
                  isOutlined: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
          );
        },
      );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}