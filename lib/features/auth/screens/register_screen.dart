import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/custom_button.dart';
import '../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'jobseeker';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw const AuthException('Please fill in all fields');
      }

      await ref
          .read(authServiceProvider)
          .register(
            email: email,
            password: password,
            fullName: name,
            role: _selectedRole,
          );

      // Sign out immediately so the auto-session from signUp doesn't
      // bypass the login screen and trap the user in profile-setup.
      await ref.read(authServiceProvider).logout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! Please log in.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to keep inputs aligned and code clean
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            isDense: true, // Reduces default vertical padding
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
            // Tighter constraints pull the icon flush with the left edge
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            suffixIcon: isPassword
                ? Icon(
                    Icons.visibility_off_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  )
                : null,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    String role,
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // Reduced vertical padding from 20.0 to 14.0
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24, // Reduced icon size from 32 to 24
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 6), // Reduced gap
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13, // Slightly smaller text
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Texture Mockup
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              color: colorScheme.primary.withOpacity(0.8),
              child: Image.asset(
                'assets/bg_texture.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          // Scrollable Form Area
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.25),
                  ClipPath(
                    clipper: WavyTopClipper(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: size.height * 0.75,
                      ),
                      color: colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 32),
                            height: 3,
                            width: 40,
                            color: colorScheme.primary,
                          ),

                          _buildInputField(
                            label: 'Full Name',
                            hint: 'John Doe',
                            icon: Icons.person_outline,
                            controller: _nameController,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            label: 'Email',
                            hint: 'demo@email.com',
                            icon: Icons.mail_outline,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            label: 'Password',
                            hint: 'enter your password',
                            icon: Icons.lock_outline,
                            controller: _passwordController,
                            isPassword: true,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 32),

                          Text(
                            'Select your role',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildRoleCard(
                                'jobseeker',
                                Icons.person,
                                'Jobseeker',
                                colorScheme,
                              ),
                              const SizedBox(width: 16),
                              _buildRoleCard(
                                'employer',
                                Icons.business,
                                'Employer',
                                colorScheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: CustomButton(
                              text: 'Register',
                              onPressed: _register,
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Login here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavyTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 60);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 40);
    path.quadraticBezierTo(size.width * 0.75, 80, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
