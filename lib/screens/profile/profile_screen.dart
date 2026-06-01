import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';

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
      
      // TODO: Implement profile update API call when backend endpoint is ready
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditing = false;
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          final user = state.auth.user;
          
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }
          
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
            _emailController.text = user.email ?? '';
            _phoneController.text = user.phone ?? '';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
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
                              color: AppTheme.primaryColor.withOpacity(0.1),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon')),
                    );
                  },
                  icon: Icons.lock_outline,
                  isOutlined: true,
                  isFullWidth: true,
                ),
              ],
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