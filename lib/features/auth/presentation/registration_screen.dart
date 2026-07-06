import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../data/registration_repository.dart';
import '../data/user_profile.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyController = TextEditingController();
  final _regNoController = TextEditingController();
  final _codeController = TextEditingController();
  AppUserRole _role = AppUserRole.student;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _facultyController.dispose();
    _regNoController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await RegistrationRepository().register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        requestedRole: _role,
        faculty: _facultyController.text,
        regNo: _regNoController.text,
        registrationCode: _codeController.text,
      );
      if (mounted) context.go('/app');
    } on FirebaseAuthException catch (error) {
      setState(() => _error = error.message ?? 'Registration failed.');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needsCode = _role != AppUserRole.student;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/vu_auth_hero.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.surface.withValues(alpha: 0.96),
                  scheme.surface.withValues(alpha: 0.88),
                  scheme.primary.withValues(alpha: 0.45),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    color: scheme.surface.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go('/login'),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Create VU Hub account',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Students can register directly. Lecturer, guild, and admin accounts require an official registration code.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'University email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Use at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<AppUserRole>(
                              initialValue: _role,
                              decoration: const InputDecoration(
                                labelText: 'Register as',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: AppUserRole.student,
                                  child: Text('Student'),
                                ),
                                DropdownMenuItem(
                                  value: AppUserRole.lecturer,
                                  child: Text('Lecturer'),
                                ),
                                DropdownMenuItem(
                                  value: AppUserRole.guildOfficial,
                                  child: Text('Guild official'),
                                ),
                                DropdownMenuItem(
                                  value: AppUserRole.admin,
                                  child: Text('Administrator'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _role = value ?? AppUserRole.student,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _facultyController,
                                    decoration: const InputDecoration(
                                      labelText: 'Faculty/department',
                                      prefixIcon: Icon(Icons.apartment),
                                    ),
                                    validator: _required,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _regNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Reg/staff no.',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: _required,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: needsCode
                                  ? Padding(
                                      key: const ValueKey('role-code'),
                                      padding: const EdgeInsets.only(top: 12),
                                      child: TextFormField(
                                        controller: _codeController,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Official registration code',
                                          prefixIcon: Icon(Icons.key_outlined),
                                          helperText:
                                              'Required for lecturer, guild, and admin accounts.',
                                        ),
                                        validator: (value) {
                                          if (_role != AppUserRole.student &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Enter your official role code.';
                                          }
                                          return null;
                                        },
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _register,
                              icon: _isLoading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.how_to_reg),
                              label: const Text('Create account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}
