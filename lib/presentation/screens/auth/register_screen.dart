import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cinealert_button.dart';
import '../../widgets/cinealert_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      context.goNamed('home');
    } else {
      final state = ref.read(authProvider);
      final msg = state is AuthError ? state.message : 'Falha ao cadastrar';
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
      appBar: AppBar(
        title: const Text('Criar conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.goNamed('login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo ao CineAlert!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),

                const SizedBox(height: 8),

                const Text(
                  'Crie sua conta e nunca mais perca um lançamento.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                CineAlertTextField(
                  controller: _nameCtrl,
                  label: 'Nome completo',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                    if (v.trim().length < 2) return 'Nome muito curto';
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                CineAlertTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                CineAlertTextField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe uma senha';
                    if (v.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                CineAlertTextField(
                  controller: _confirmCtrl,
                  label: 'Confirmar senha',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                  onSubmitted: (_) => _register(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme sua senha';
                    if (v != _passwordCtrl.text) return 'As senhas não coincidem';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),

                CineAlertButton(
                  label: 'Cadastrar',
                  isLoading: isLoading,
                  onPressed: _register,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => context.goNamed('login'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Já tem conta? ',
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Entrar',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
