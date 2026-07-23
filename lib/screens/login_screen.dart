import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(username, password);

    if (!success && mounted) {
      final msg = authProvider.errorMessage ?? 'Login failed';
      final isConnectionError = msg.contains('too long') || msg.contains('reach') || msg.contains('Connection error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: isConnectionError ? 6 : 4),
          action: isConnectionError
              ? SnackBarAction(
                  label: 'Configure Server',
                  textColor: Colors.white,
                  onPressed: () => _showServerConfigDialog(context),
                )
              : null,
        ),
      );
    }
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: AuthService.baseUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text('SERVER CONFIGURATION', style: TextStyle(color: AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter target Spring Boot server base URL address:', style: TextStyle(color: AppTheme.outline, fontSize: 11)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. http://192.168.1.5:8080',
                  hintStyle: const TextStyle(color: AppTheme.outline),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.surfaceContainerHighest),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.outline, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                await AuthService.setCustomBaseUrl(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL set to: ${AuthService.baseUrl}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                }
              },
              child: const Text('APPLY', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.outline),
            onPressed: () => _showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'RESQNET MOBILE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tactical Mesh Authentication',
                  style: TextStyle(fontSize: 12, color: AppTheme.outline),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'USERNAME OR EMAIL',
                    labelStyle: const TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.outline, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.surfaceContainerHighest),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    labelStyle: const TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.outline, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.surfaceContainerHighest),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: AppTheme.outline, fontSize: 13)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text('Sign Up', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
