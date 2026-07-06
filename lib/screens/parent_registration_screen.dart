import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _occupationController = TextEditingController();
  
  // Address Controller
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleRegister(Store<AppState> store) {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      PopupNotification.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final parentData = <String, dynamic>{
      'fullName': _fullNameController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
    };

    if (_alternatePhoneController.text.isNotEmpty) {
      parentData['alternatePhone'] = _alternatePhoneController.text;
    }
    if (_emailController.text.isNotEmpty) {
      parentData['email'] = _emailController.text;
    }
    if (_occupationController.text.isNotEmpty) {
      parentData['occupation'] = _occupationController.text;
    }
    if (_addressController.text.isNotEmpty) {
      parentData['address'] = _addressController.text;
    }

    store.dispatch(registerParentThunk(RegisterParentAction(
      parentData: parentData,
      onResult: (success, error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        if (success) {
          PopupNotification.showSuccess(context, 'Registration successful! Please login.');
          Navigator.of(context).pop();
        } else {
          PopupNotification.showError(context, error ?? 'Registration failed');
        }
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('Parent Registration'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A2B4B)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A2B4B),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StoreConnector<AppState, Store<AppState>>(
        converter: (store) => store,
        builder: (context, store) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header text
                    const Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please fill in your details to register as a parent.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Information Section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address (Optional)',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.isNotEmpty && !v.contains('@') ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _occupationController,
                      label: 'Occupation (Optional)',
                      prefixIcon: Icons.work_outline,
                    ),
                    const SizedBox(height: 32),

                    // Contact Information Section
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _phoneController,
                            label: 'Mobile Number *',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty || v.length < 10 ? 'Invalid phone' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _alternatePhoneController,
                            label: 'Alternate Mobile (Optional)',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Address Section
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address (Optional)',
                      prefixIcon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 32),

                    // Security Section
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password *',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) => v!.isEmpty || v.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password *',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_showConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 48),

                    // Register Button
                    CustomButton(
                      text: 'Register Account',
                      onPressed: () => _handleRegister(store),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
