import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        requestedRole: _role,
        faculty: _facultyController.text.trim(),
        regNo: _regNoController.text.trim(),
        registrationCode: _codeController.text.trim(),
      );
      if (mounted) context.go('/app');
    } on FirebaseAuthException catch (error) {
      String friendlyMessage = 'Registration failed. Please try again.';
      switch (error.code) {
        case 'email-already-in-use':
          friendlyMessage = 'This email is already registered. Please sign in.';
          break;
        case 'invalid-email':
          friendlyMessage = 'Please enter a valid university email address.';
          break;
        case 'weak-password':
          friendlyMessage =
              'Password is too weak. Please use a stronger password.';
          break;
        case 'network-request-failed':
          friendlyMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          if (error.message != null && !error.message!.contains('pigeon')) {
            friendlyMessage = error.message!;
          }
      }
      setState(() => _error = friendlyMessage);
    } catch (error) {
      setState(() => _error = error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRoleDisplayName(AppUserRole role) {
    switch (role) {
      case AppUserRole.student:
        return 'Student';
      case AppUserRole.lecturer:
        return 'Lecturer';
      case AppUserRole.guildOfficial:
        return 'Guild Official';
      case AppUserRole.admin:
        return 'Administrator';
      default:
        return 'Student';
    }
  }

  void _showRolePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Campus Role',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _RoleOptionTile(
                title: 'Student',
                subtitle: 'Default access to campus resources',
                icon: Icons.school_outlined,
                isSelected: _role == AppUserRole.student,
                onTap: () {
                  setState(() => _role = AppUserRole.student);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _RoleOptionTile(
                title: 'Lecturer',
                subtitle: 'Requires official staff code',
                icon: Icons.work_outline,
                isSelected: _role == AppUserRole.lecturer,
                onTap: () {
                  setState(() => _role = AppUserRole.lecturer);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _RoleOptionTile(
                title: 'Guild Official',
                subtitle: 'Requires guild representative code',
                icon: Icons.how_to_reg_outlined,
                isSelected: _role == AppUserRole.guildOfficial,
                onTap: () {
                  setState(() => _role = AppUserRole.guildOfficial);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _RoleOptionTile(
                title: 'Administrator',
                subtitle: 'Requires system admin code',
                icon: Icons.admin_panel_settings_outlined,
                isSelected: _role == AppUserRole.admin,
                onTap: () {
                  setState(() => _role = AppUserRole.admin);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? scheme.surface : Colors.white;
    final onBgColor = isDark ? Colors.white : Colors.black;
    final headerTextColor = Colors.white;

    final needsCode = _role != AppUserRole.student;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Background Header Image with gradient fade
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/p6.jpeg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.6),
                          bgColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo
                        Image.asset('assets/images/vu_hub_logo.png', height: 72)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),

                        // Header Text
                        Text(
                              'Join VU Hub',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: headerTextColor,
                                    height: 1.1,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 12),
                        Text(
                              'Create your secure campus profile to access notices, resources, and events.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.5,
                                  ),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 48),

                        // Input Form
                        Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? scheme.surfaceContainerHighest.withValues(
                                        alpha: 0.5,
                                      )
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                                boxShadow: isDark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _PremiumTextFormField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      textInputAction: TextInputAction.next,
                                      validator: _required,
                                    ),
                                    const SizedBox(height: 16),
                                    _PremiumTextFormField(
                                      controller: _emailController,
                                      label: 'University Email',
                                      icon: Icons.mail_outline,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      validator: _required,
                                    ),
                                    const SizedBox(height: 16),
                                    _PremiumTextFormField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.length < 6) {
                                          return 'Use at least 6 characters.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Premium Role Selector
                                    InkWell(
                                      onTap: () => _showRolePicker(context),
                                      borderRadius: BorderRadius.circular(16),
                                      child: InputDecorator(
                                        decoration:
                                            _buildInputDecoration(
                                              context,
                                              'Campus Role',
                                              Icons.verified_user_outlined,
                                            ).copyWith(
                                              suffixIcon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black45,
                                              ),
                                            ),
                                        child: Text(
                                          _getRoleDisplayName(_role),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _PremiumTextFormField(
                                            controller: _facultyController,
                                            label: 'Faculty',
                                            icon: Icons.apartment,
                                            validator: _required,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _PremiumTextFormField(
                                            controller: _regNoController,
                                            label: 'Reg/Staff No.',
                                            icon: Icons.badge_outlined,
                                            validator: _required,
                                          ),
                                        ),
                                      ],
                                    ),

                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          SizeTransition(
                                            sizeFactor: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: needsCode
                                          ? Padding(
                                              key: const ValueKey('role-code'),
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                              ),
                                              child: _PremiumTextFormField(
                                                controller: _codeController,
                                                label:
                                                    'Official Registration Code',
                                                icon: Icons.key_outlined,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .characters,
                                                validator: (value) {
                                                  if (needsCode &&
                                                      (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty)) {
                                                    return 'Role code is required.';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            )
                                          : const SizedBox.shrink(
                                              key: ValueKey('no-code'),
                                            ),
                                    ),

                                    if (_error != null) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.errorContainer
                                              .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: scheme.error,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: TextStyle(
                                                  color: scheme.error,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 32),

                                    // Register Button
                                    FilledButton(
                                      onPressed: _isLoading ? null : _register,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: onBgColor,
                                        foregroundColor: bgColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: bgColor,
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.05, end: 0),

                        const SizedBox(height: 32),

                        // Login Navigation
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: onBgColor,
                                ),
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Back Button at Top
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white54 : Colors.black54,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black45),
      filled: true,
      fillColor: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}

class _PremiumTextFormField extends StatelessWidget {
  const _PremiumTextFormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black45),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}

class _RoleOptionTile extends StatelessWidget {
  const _RoleOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? scheme.primary
                  : (isDark ? Colors.white54 : Colors.black54),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
