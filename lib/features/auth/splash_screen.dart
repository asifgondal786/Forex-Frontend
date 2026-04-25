import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    // Wait for auth to resolve
    if (auth.status == AuthStatus.unknown) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated ? const AppShell() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo glow
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(100),
                        blurRadius: 40, spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('T',
                        style: TextStyle(
                          fontSize: 52, fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('TAJIR',
                    style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, letterSpacing: 8,
                    )),
                const SizedBox(height: 8),
                const Text('You Sleep. I Earn.',
                    style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 60),
                SizedBox(
                  width: 32, height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.bg3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}