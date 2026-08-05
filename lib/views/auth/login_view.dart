import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../widgets/aspire_logo.dart';
import 'forgot_password_view.dart';
import '../main_navigation_hub.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final api = Provider.of<ApiService>(context, listen: false);
      final success = await api.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationHub()),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(api.errorMessage ?? 'Invalid credentials'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _quickLogin(String email, String password) {
    _identifierController.text = email;
    _passwordController.text = password;
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? AspireColors.darkCard : AspireColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? AspireColors.darkBorder
                      : AspireColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  const Center(
                    child: AspireLogo(
                      size: 55,
                      showText: true,
                      isDarkBackground: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aspire Workflow Engine',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AspireColors.darkTextSecondary
                          : AspireColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Identifier Input
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'Email or Mobile Number',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or mobile';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordView()),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  Consumer<ApiService>(
                    builder: (context, api, _) {
                      return ElevatedButton(
                        onPressed: api.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AspireColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: api.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Secure Login'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Demo Accounts Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: isDark
                                  ? AspireColors.darkBorder
                                  : AspireColors.lightBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'QUICK MOCK LOGINS',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: isDark
                                  ? AspireColors.darkBorder
                                  : AspireColors.lightBorder)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mock logins buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: const Text('Super Admin'),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        side: BorderSide.none,
                        onPressed: () =>
                            _quickLogin('admin@aspire.com', 'password123'),
                      ),
                      ActionChip(
                        label: const Text('Manager'),
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.1),
                        side: BorderSide.none,
                        onPressed: () =>
                            _quickLogin('manager@aspire.com', 'password123'),
                      ),
                      ActionChip(
                        label: const Text('Team Leader'),
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.1),
                        side: BorderSide.none,
                        onPressed: () =>
                            _quickLogin('tl@aspire.com', 'password123'),
                      ),
                      ActionChip(
                        label: const Text('Staff (Sales)'),
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.1),
                        side: BorderSide.none,
                        onPressed: () =>
                            _quickLogin('staff@aspire.com', 'password123'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
