import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_ai/features/auth/domain/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'dart:ui';

class LoginPage extends ConsumerStatefulWidget {
  final AuthService authService;

  const LoginPage({
    super.key,
    required this.authService,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = await widget.authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          ref.read(currentUserProvider.notifier).state = user;
          context.go('/dashboard');
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8E24AA);
    return Scaffold(
      backgroundColor: null,
      body: Stack(
        children: [
          // Apple-style gradient and bokeh background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F8FA), Color(0xFFE3E6F0), Color(0xFFF3EFFF)],
              ),
            ),
            child: Stack(
              children: [
                // Bokeh circles
                Positioned(
                  top: 60,
                  left: 30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 60, color: Colors.white.withOpacity(0.18))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: 40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 50, color: Colors.white.withOpacity(0.13))],
                    ),
                  ),
                ),
                Positioned(
                  top: 200,
                  right: 100,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 30, color: Colors.white.withOpacity(0.10))],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Material(
            type: MaterialType.transparency,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: accentColor.withOpacity(0.13),
                                          child: Icon(Icons.school_rounded, color: accentColor, size: 38),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Teacher AI',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                            letterSpacing: -1.1,
                                            color: Colors.black.withOpacity(0.82),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      'Sign In',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                        letterSpacing: -1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Divider(height: 1, color: Colors.grey.withOpacity(0.13)),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.7),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your email';
                                      }
                                      if (!value!.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.7),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.45),
                                      foregroundColor: accentColor,
                                      shadowColor: accentColor.withOpacity(0.13),
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
                                    ),
                                    onPressed: _isLoading ? null : _handleLogin,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          // TODO: Implement forgot password
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey[700],
                                          textStyle: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        child: const Text('Forgot Password?'),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/register'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: accentColor,
                                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        child: const Text('Create Account'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
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
            ),
          ),
        ],
      ),
    );
  }
} 