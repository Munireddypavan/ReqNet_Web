import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _fullNameController.text = user['fullName'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
      }
      _initialized = true;
    }
  }

  void _handleSave() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address cannot be empty.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _passwordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Update failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(
        child: Text('Not authenticated', style: TextStyle(color: AppTheme.onSurface)),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const Text('TACTICAL OPERATOR PROFILE', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            (user['fullName'] != null && user['fullName'].toString().isNotEmpty)
                ? user['fullName'].toString().toUpperCase()
                : 'OPERATOR PROFILE',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1.0, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'USERNAME: ${user['username']?.toString().toUpperCase()}',
            style: const TextStyle(fontSize: 12, color: AppTheme.outline, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _fullNameController,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: _buildInputDecoration('FULL NAME', Icons.badge_outlined),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: _buildInputDecoration('EMAIL ADDRESS', Icons.email_outlined),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: _buildInputDecoration('PHONE NUMBER', Icons.phone_outlined),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: _buildInputDecoration('NEW PASSWORD (LEAVE EMPTY TO KEEP CURRENT)', Icons.lock_outlined),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: authProvider.isLoading ? null : _handleSave,
              icon: authProvider.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
              label: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_outlined, color: AppTheme.error, size: 18),
              label: const Text('LOGOUT', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error, width: 1.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: AppTheme.outline, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.surfaceContainerHighest),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}
