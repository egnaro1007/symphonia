import 'package:flutter/material.dart';
import 'package:symphonia/screens/navigation_bar_screen.dart';
import 'package:symphonia/services/user_info_manager.dart';
import '../../services/token_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _login();
      } else {
        await _signup();
      }
    } catch (e) {
      setState(() {
        _errorMessage = _isLoginMode
            ? 'Invalid credentials or connection error. Please try again.'
            : 'Failed to create account. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    await TokenManager.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    await UserInfoManager.fetchUserInfo();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationBarScreen(selectedBottom: 3),
        ),
      );
    }
  }

  Future<void> _signup() async {
    // Add your signup logic here
    // This should call a method in TokenManager or a different service to register the user
    // For example:
    // await UserService.register(_usernameController.text.trim(), _passwordController.text);

    // After successful signup, automatically log the user in
    await _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Symphonia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isLoginMode ? null : _switchMode,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _isLoginMode ? FontWeight.bold : FontWeight.normal,
                              color: _isLoginMode ? Colors.purpleAccent : Colors.grey,
                            ),
                          ),
                        ),
                        const Text(
                          '|',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: _isLoginMode ? _switchMode : null,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: !_isLoginMode ? FontWeight.bold : FontWeight.normal,
                              color: !_isLoginMode ? Colors.purpleAccent : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.grey.shade300),
                        prefixIcon: Icon(Icons.person, color: Colors.grey.shade300),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.purpleAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey.shade300),
                        prefixIcon: Icon(Icons.lock, color: Colors.grey.shade300),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.purpleAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),

                    // Conditional confirm password field for signup
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: Colors.grey.shade300),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade300),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.purpleAccent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLoginMode ? 'Log In' : 'Sign Up',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    if (_isLoginMode) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}