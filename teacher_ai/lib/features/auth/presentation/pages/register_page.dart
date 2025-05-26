import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_ai/features/auth/domain/models/user.dart';
import 'package:teacher_ai/features/auth/domain/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'dart:ui';

class RegisterPage extends ConsumerStatefulWidget {
  final AuthService authService;

  const RegisterPage({
    super.key,
    required this.authService,
  });

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _titleOptions = ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'];
  String? _selectedTitle;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = User(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          title: _selectedTitle!,
        );

        final success = await widget.authService.register(user);

        if (success && mounted) {
          ref.read(currentUserProvider.notifier).state = user;
          context.go('/dashboard');
        } else {
          setState(() {
            _errorMessage = 'A user with this email already exists';
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
    return Stack(
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
                                Center(
                                  child: Text(
                                    'Create Account',
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
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          labelText: 'First Name',
                                          prefixIcon: const Icon(Icons.person_outline),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.7),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Please enter your first name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          labelText: 'Last Name',
                                          prefixIcon: const Icon(Icons.person_outline),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.7),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Please enter your last name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedTitle,
                                  decoration: InputDecoration(
                                    labelText: 'Title',
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.7),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _titleOptions.map((title) => DropdownMenuItem(
                                    value: title,
                                    child: Text(title),
                                  )).toList(),
                                  onChanged: (value) => setState(() => _selectedTitle = value),
                                  validator: (value) => value == null ? 'Please select a title' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
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
                                    prefixIcon: const Icon(Icons.lock_outline),
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
                                      return 'Please enter a password';
                                    }
                                    if (value!.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
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
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
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
                                  onPressed: _isLoading ? null : _handleRegister,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Already have an account?'),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: accentColor,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      child: const Text('Login'),
                                    ),
                                  ],
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
          ),
        ),
      ],
    );
  }
} 