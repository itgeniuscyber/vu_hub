import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      String friendlyMessage =
          'Could not sign in. Please check your credentials.';
      switch (error.code) {
        case 'user-not-found':
          friendlyMessage = 'No student found with this email.';
          break;
        case 'wrong-password':
          friendlyMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          friendlyMessage = 'Please enter a valid university email address.';
          break;
        case 'user-disabled':
          friendlyMessage =
              'This account has been disabled. Please contact support.';
          break;
        case 'invalid-credential':
          friendlyMessage = 'Incorrect email or password.';
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
    } catch (e) {
      setState(
        () => _error = 'An unexpected error occurred. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? scheme.surface
        : const Color.fromARGB(255, 238, 143, 143);
    // Keep text white over the image area, regardless of theme
    final onBgColor = isDark
        ? const Color.fromARGB(255, 194, 190, 190)
        : Colors.black;
    final headerTextColor = Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Always light over dark image
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
              height:
                  MediaQuery.of(context).size.height * 0.55, // Increased height
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/gal-6.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // Darker overlay at the top to make logo/back button pop
                          Colors.black.withValues(alpha: 0.4),
                          // Darker middle to make white text readable
                          Colors.black.withValues(alpha: 0.6),
                          // Fade into the actual background color at the bottom
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
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 4.6,
                        ), // Push down slightly
                        // Logo
                        Image.asset(
                              'assets/images/vu_hub_logo.png',
                              height: 120,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 10),

                        // Header Text
                        Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: headerTextColor, // Always white
                                    height: 1.1,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 5),
                        Text(
                              'Sign in to access your VU Hub dashboard, resources, and live campus events.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(
                                      alpha: 0.85,
                                    ), // Always whitish
                                    height: 1.5,
                                  ),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 15),

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _PremiumTextField(
                                    controller: _emailController,
                                    label: 'Enter Your Email',
                                    icon: BoldRounded.envelope,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 15),
                                  _PremiumTextField(
                                    controller: _passwordController,
                                    label: 'Enter Password',
                                    icon: BoldRounded.lock,
                                    obscureText: _obscurePassword,
                                    onSubmitted: (_) => _signIn(),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: FUI(
                                        _obscurePassword
                                            ? BoldRounded.eyeCrossed
                                            : BoldRounded.eye,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),

                                  if (_error != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.errorContainer.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          FUI(
                                            BoldRounded.exclamation,
                                            color: scheme.error,
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: TextStyle(
                                                color: scheme.error,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Add forgot password navigation later if needed
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: scheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // Login Button
                                  FilledButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: onBgColor,
                                      foregroundColor: bgColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.05, end: 0),

                        const SizedBox(height: 15),

                        // Create Account / Navigation
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                style: TextButton.styleFrom(
                                  foregroundColor: onBgColor,
                                ),
                                child: const Text(
                                  'Sign up',
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

            // Back/Onboarding Button at Top
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: IconButton(
                  onPressed: () => context.go('/onboarding'),
                  icon: const FUI(BoldRounded.arrowLeft),
                  color: isDark ? Colors.white : Colors.black87,
                  style: IconButton.styleFrom(
                    backgroundColor: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: isDark
            ? const Color.fromARGB(255, 221, 214, 214)
            : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13),
          child: FUI(
            icon,
            color: isDark ? Colors.white54 : Colors.black45,
            width: 20,
            height: 20,
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
