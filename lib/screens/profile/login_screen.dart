import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/screens/navigation_bar_screen.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'package:symphonia/controller/player_controller.dart';
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
        _errorMessage =
            _isLoginMode
                ? AppLocalizations.of(context)!.wrongCredentials
                : AppLocalizations.of(context)!.createAccountFailed;
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

    // Reset player state when switching users
    final playerController = PlayerController.getInstance();
    await playerController.reset();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => NavigationBarScreen(selectedBottom: 0),
        ),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    }
  }

  Future<void> _signup() async {
    await TokenManager.signup(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoginMode = true;
        _errorMessage = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.accountCreatedSuccessfully,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Clear password fields
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
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
                      Text(
                        AppLocalizations.of(context)!.appTitle,
                        style: const TextStyle(
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
                              AppLocalizations.of(context)!.login,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _isLoginMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    _isLoginMode
                                        ? Colors.purpleAccent
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          const Text('|', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: _isLoginMode ? _switchMode : null,
                            child: Text(
                              AppLocalizations.of(context)!.signUp,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    !_isLoginMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    !_isLoginMode
                                        ? Colors.purpleAccent
                                        : Colors.grey,
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
                          labelText:
                              _isLoginMode
                                  ? "Username hoặc Email"
                                  : AppLocalizations.of(context)!.username,
                          labelStyle: TextStyle(color: Colors.grey.shade300),
                          hintText:
                              _isLoginMode ? "Nhập username hoặc email" : null,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            _isLoginMode ? Icons.account_circle : Icons.person,
                            color: Colors.grey.shade300,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.purpleAccent,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _isLoginMode
                                ? "Vui lòng nhập username hoặc email"
                                : AppLocalizations.of(
                                  context,
                                )!.pleaseEnterUsername;
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
                          labelText: AppLocalizations.of(context)!.password,
                          labelStyle: TextStyle(color: Colors.grey.shade300),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Colors.grey.shade300,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.purpleAccent,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            )!.pleaseEnterPassword;
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
                            labelText:
                                AppLocalizations.of(context)!.confirmPassword,
                            labelStyle: TextStyle(color: Colors.grey.shade300),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade300,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.purpleAccent,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.pleaseConfirmPassword;
                            }
                            if (value != _passwordController.text) {
                              return AppLocalizations.of(
                                context,
                              )!.passwordsDoNotMatch;
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
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  _isLoginMode
                                      ? AppLocalizations.of(context)!.login
                                      : AppLocalizations.of(context)!.signUp,
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
                          child: Text(
                            AppLocalizations.of(context)!.forgotPassword,
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
      ),
    );
  }
}
