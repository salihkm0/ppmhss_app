import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isEmailLogin = true;
  String? _lastShownError;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(Store<AppState> store) async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final action = LoginAction(
      email: _isEmailLogin ? _emailController.text : null,
      phone: !_isEmailLogin ? _phoneController.text : null,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    await store.dispatch(loginThunk(action));
    
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      onInit: (store) {
        // Clear any existing error when screen initializes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          store.dispatch(ClearAuthErrorAction());
        });
      },
      builder: (context, state) {
        final store = StoreProvider.of<AppState>(context);
        
        // Show error only once when it changes
        if (state.auth.error != null && state.auth.error != _lastShownError && mounted) {
          _lastShownError = state.auth.error;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              PopupNotification.showError(context, state.auth.error!);
            }
          });
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school,
                            size: 50,
                            color: AppTheme.primaryColor,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _isEmailLogin = true;
                                  _lastShownError = null;
                                });
                                store.dispatch(ClearAuthErrorAction());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isEmailLogin ? AppTheme.primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Email',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isEmailLogin ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (mounted) {
                                setState(() {
                                  _isEmailLogin = false;
                                  _lastShownError = null;
                                });
                                store.dispatch(ClearAuthErrorAction());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isEmailLogin ? AppTheme.primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Mobile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isEmailLogin ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isEmailLogin)
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          )
                        else
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Mobile Number',
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (value.length < 10) {
                                return 'Enter a valid mobile number';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_showPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() => _showPassword = !_showPassword);
                              }
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Remember me & Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => _rememberMe = value ?? false);
                              }
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          PopupNotification.showInfo(context, 'Password reset link will be sent to your email');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Sign In',
                    onPressed: () => _handleLogin(store),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  // Parent Registration Link
                  TextButton(
                    onPressed: () {
                      PopupNotification.showInfo(context, 'Parent registration feature coming soon');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('New Parent? Register Here'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}