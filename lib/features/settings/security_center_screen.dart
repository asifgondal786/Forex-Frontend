// lib/features/settings/security_center_screen.dart
// Security centre â€” PIN lock, biometric toggle, session info.
// Uses AuthProvider (not the deleted UserProvider).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/security_service.dart';
import '../../services/security_lockout_service.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  bool _biometricEnabled  = false;
  bool _pinEnabled        = false;
  bool _loadingBiometric  = false;
  int  _failedAttempts    = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ss = context.read<SecurityService>();
    final ls = context.read<SecurityLockoutService>();
    final bio = await ss.isBiometricEnabled();
    final pin = await ss.isPinEnabled();
    setState(() {
      _biometricEnabled = bio;
      _pinEnabled       = pin;
      _failedAttempts   = SecurityLockoutService.failedAttempts;
    });
  }

  Future<void> _toggleBiometric(bool val) async {
    setState(() => _loadingBiometric = true);
    final ss = context.read<SecurityService>();
    try {
      if (val) {
        await ss.enableBiometric();
      } else {
        await ss.disableBiometric();
      }
      setState(() => _biometricEnabled = val);
    } catch (e) {
      _showSnack('Biometric change failed: $e');
    } finally {
      setState(() => _loadingBiometric = false);
    }
  }

  Future<void> _togglePin(bool val) async {
    final ss = context.read<SecurityService>();
    if (val) {
      await _showSetPinDialog(ss);
    } else {
      await ss.disablePin();
      setState(() => _pinEnabled = false);
    }
  }

  Future<void> _showSetPinDialog(SecurityService ss) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Set PIN',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '4â€“6 digit PIN',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            counterStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed == true && controller.text.length >= 4) {
      await ss.enablePin(controller.text);
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        title: const Text('Security Centre',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // â”€â”€ Account info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionCard(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.primary),
                ),
                title: Text(user?.email ?? 'Not signed in',
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Signed in account',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // â”€â”€ Authentication â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: 'Authentication'),
          _SectionCard(
            children: [
              SwitchListTile(
                value: _biometricEnabled,
                onChanged: _loadingBiometric ? null : _toggleBiometric,
                activeColor: AppColors.primary,
                title: const Text('Biometric Login',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Fingerprint / Face ID',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                secondary: _loadingBiometric
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.fingerprint,
                        color: AppColors.textSecondary),
              ),
              const Divider(color: AppColors.bg3, height: 1),
              SwitchListTile(
                value: _pinEnabled,
                onChanged: _togglePin,
                activeColor: AppColors.primary,
                title: const Text('PIN Lock',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('4â€“6 digit app lock',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                secondary: const Icon(Icons.lock_outline,
                    color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // â”€â”€ Session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: 'Session'),
          _SectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                title: const Text('Failed Login Attempts',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: Text('$_failedAttempts',
                    style: TextStyle(
                        color: _failedAttempts > 0
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const Divider(color: AppColors.bg3, height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded,
                    color: AppColors.danger),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.bg2,
                      title: const Text('Sign Out?',
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text(
                          'You will need to sign in again to access Tajir.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) _signOut();
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // â”€â”€ Disclaimer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Tajir stores credentials securely using device keychain. '
              'PIN and biometric settings are local to this device.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Helper widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bg3),
      ),
      child: Column(children: children),
    );
  }
}

