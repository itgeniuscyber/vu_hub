import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../data/registration_repository.dart';
import '../data/user_profile.dart';
import 'auth_shared.dart';

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
  bool _obscurePassword = true;
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
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final form = _RegistrationForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      facultyController: _facultyController,
                      regNoController: _regNoController,
                      codeController: _codeController,
                      role: _role,
                      obscurePassword: _obscurePassword,
                      isLoading: _isLoading,
                      error: _error,
                      onBack: () => context.go('/login'),
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onRoleChanged: (value) =>
                          setState(() => _role = value ?? AppUserRole.student),
                      onRegister: _register,
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RegistrationIntro(),
                          const SizedBox(height: 18),
                          form,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: _RegistrationStory()),
                        const SizedBox(width: 28),
                        SizedBox(width: 470, child: form),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationIntro extends StatelessWidget {
  const _RegistrationIntro();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your campus account',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Students can register directly. Staff, guild, and admin roles need official codes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0);
  }
}

class _RegistrationStory extends StatelessWidget {
  const _RegistrationStory();

  @override
  Widget build(BuildContext context) {
    return const AuthShowcasePanel(
      eyebrow: 'Build Your VU Presence',
      title:
          'A cleaner onboarding path for students, lecturers, guild, and admins.',
      subtitle:
          'The new registration flow gives users a clearer layout, stronger role guidance, and a more premium first impression.',
      tags: ['Role-aware', 'Clean forms', 'Secure auth', 'Guided setup'],
      highlights: [
        AuthHighlight(
          icon: Icons.school_outlined,
          title: 'Student-first by default',
          subtitle:
              'Regular students can register with minimal friction, while elevated roles stay protected behind official codes.',
        ),
        AuthHighlight(
          icon: Icons.badge_outlined,
          title: 'Role-aware experience',
          subtitle:
              'Registration collects just enough profile detail to personalize the app and support later role-based access.',
        ),
        AuthHighlight(
          icon: Icons.lock_person_outlined,
          title: 'Secure from the start',
          subtitle:
              'Passwords are handled only through Firebase Authentication and are never exposed from Firestore.',
        ),
      ],
    );
  }
}

class _RegistrationForm extends StatelessWidget {
  const _RegistrationForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.facultyController,
    required this.regNoController,
    required this.codeController,
    required this.role,
    required this.obscurePassword,
    required this.isLoading,
    required this.error,
    required this.onBack,
    required this.onTogglePassword,
    required this.onRoleChanged,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController facultyController;
  final TextEditingController regNoController;
  final TextEditingController codeController;
  final AppUserRole role;
  final bool obscurePassword;
  final bool isLoading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onTogglePassword;
  final ValueChanged<AppUserRole?> onRoleChanged;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needsCode = role != AppUserRole.student;
    return AuthGlassPane(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create VU Hub account',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set up your secure profile and choose the right campus role.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AuthInfoBanner(
              icon: Icons.shield_outlined,
              title: 'Safe account setup',
              message:
                  'The app stores only profile metadata and role details in Firestore. Passwords stay in Firebase Authentication only.',
            ),
            const SizedBox(height: 18),
            const AuthSectionTitle(
              title: 'Profile details',
              subtitle: 'These basics help personalize the student experience.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'University email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Use at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const AuthSectionTitle(
              title: 'Campus role',
              subtitle:
                  'Students register directly. Elevated roles require official approval.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AppUserRole>(
              initialValue: role,
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
              onChanged: onRoleChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: facultyController,
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
                    controller: regNoController,
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
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Official registration code',
                          prefixIcon: Icon(Icons.key_outlined),
                          helperText:
                              'Required for lecturer, guild, and admin accounts.',
                        ),
                        validator: (value) {
                          if (role != AppUserRole.student &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Enter your official role code.';
                          }
                          return null;
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isLoading ? null : onRegister,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.how_to_reg),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0);
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}
