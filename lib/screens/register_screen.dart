import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _hasError = true;
    });
  }

  void _hideError() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Register the user
      final registerResult = await ApiService.register(
        _usernameController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (registerResult['success']) {
        // Registration successful - show success message and redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in to continue.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Registration failed
        setState(() {
          _hasError = true;
          _errorMessage = registerResult['error'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: FadeTransition(
                  opacity: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(40.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          const Text(
                            '📱 SMS Gateway',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Create your account to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // Username Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF667eea),
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username is required';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                                onTap: _hideError,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Phone Number Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter your phone number',
                                  helperText: 'Format: 0612345678',
                                  helperStyle: const TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 12,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    color: Color(0xFF667eea),
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  // Basic phone number validation (adjust as needed)
                                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                                    return 'Enter a valid 10-digit phone number';
                                  }
                                  return null;
                                },
                                onTap: _hideError,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF667eea),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF667eea),
                                      size: 20,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFe1e1e1),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF667eea),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
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
                                onTap: _hideError,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors.white.withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Creating account...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          '🚀 Create Account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          // Error Message
                          if (_hasError) ...[
                            const SizedBox(height: 15),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe74c3c).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFe74c3c).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFFe74c3c),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],

                          // Login Section
                          const SizedBox(height: 20),
                          const Divider(
                            color: Color(0xFFe1e1e1),
                            thickness: 1,
                          ),
                          const SizedBox(height: 15),
                          
                          // Already have an account text
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _navigateToLogin,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF667eea),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '🔑 Sign In',
                                style: TextStyle(
                                  color: Color(0xFF667eea),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}