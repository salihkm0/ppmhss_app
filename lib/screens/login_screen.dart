import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/custom_text_field.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/biometric_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = '';

  bool _biometricEnabled = false;
  bool _isCheckingBiometrics = true;
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      print('Failed to get app version: $e');
    }
  }

  Future<void> _checkBiometrics() async {
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (isEnabled) {
      final available = await BiometricService.getAvailableBiometrics();
      if (mounted) {
        setState(() {
          _biometricEnabled = true;
          _biometricIcon = available.contains(BiometricType.face)
              ? Icons.face
              : Icons.fingerprint;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isCheckingBiometrics = false;
      });
    }
  }

  Future<void> _triggerBiometricLogin(Store<AppState> store) async {
    final authenticated = await BiometricService.authenticate();
    if (authenticated) {
      final credentials = await BiometricService.getCredentials();
      if (credentials != null) {
        if (!mounted) return;
        setState(() => _isLoading = true);
        final action = LoginAction(
          email: credentials['email'],
          password: credentials['password']!,
          rememberMe: true,
          isBiometric: true,
        );
        await store.dispatch(loginThunk(action));
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

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
      email: _isEmailLogin ? _emailController.text.trim() : null,
      phone: !_isEmailLogin ? _phoneController.text.trim() : null,
      password: _passwordController.text.trim(),
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
          backgroundColor: const Color(0xFFF8F9FC),
          body: Stack(
            children: [
              // Top Image Area
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://ppmhsskottukkara.com/wp-content/uploads/2018/06/WhatsApp-Image-2018-06-09-at-5.02.13-PM-768x363.jpeg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: const Color(0xFF1E3A5F).withOpacity(0.85),
                    ),
                  ],
                ),
              ),
              
              // SafeArea for Content
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Mobile Logo Overlay
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'PPMHSS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2B4B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Kottukkara',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                          const Expanded(child: SizedBox(height: 32)),
                    
                    // Form Area
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2B4B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please log in to access your portal.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Login Method Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
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
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isEmailLogin ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: _isEmailLogin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: 16,
                                            color: _isEmailLogin ? const Color(0xFF1A2B4B) : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Staff',
                                            style: TextStyle(
                                              color: _isEmailLogin ? const Color(0xFF1A2B4B) : Colors.grey[400],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
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
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isEmailLogin ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: !_isEmailLogin
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone_android_outlined,
                                            size: 16,
                                            color: !_isEmailLogin ? const Color(0xFF1A2B4B) : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Parent',
                                            style: TextStyle(
                                              color: !_isEmailLogin ? const Color(0xFF1A2B4B) : Colors.grey[400],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                const SizedBox(height: 16),
                                // Remember me & Forgot password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              if (mounted) {
                                                setState(() => _rememberMe = value ?? false);
                                              }
                                            },
                                            activeColor: const Color(0xFF1A2B4B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remember me',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        PopupNotification.showInfo(context, 'Password reset link will be sent to your email');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF1A2B4B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                if (_biometricEnabled && !_isCheckingBiometrics) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade300)),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade300)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _triggerBiometricLogin(store),
                                    icon: Icon(_biometricIcon, color: AppTheme.primaryColor),
                                    label: Text('Login with Biometrics', style: TextStyle(color: AppTheme.primaryColor)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Parent Registration Link
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register-parent');
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'New Parent? Register Here',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_appVersion.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'v$_appVersion',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}