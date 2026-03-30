import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cinealert_button.dart';
import '../../widgets/cinealert_logo.dart';
import '../../widgets/cinealert_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    if (success) {
      context.goNamed('home');
    } else {
      final state = ref.read(authProvider);
      final msg = state is AuthError ? state.message : 'Falha ao entrar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Logo
                const CineAlertLogo(size: 80, showText: true)
                    .animate().scale(duration: 400.ms, curve: Curves.easeOut),

                const SizedBox(height: 8),

                const Text(
                  'Entre para seus lembretes',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                CineAlertTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                CineAlertTextField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 20),
                  onSubmitted: (_) => _login(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),

                const SizedBox(height: 24),

                CineAlertButton(
                  label: 'Entrar',
                  isLoading: isLoading,
                  onPressed: _login,
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 24),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                CineAlertButton(
                  label: 'Criar conta',
                  outlined: true,
                  onPressed: () => context.goNamed('register'),
                  icon: Icons.person_add_outlined,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext ctx) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                    content: Text('Se o email existir, você receberá o link!')),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
