import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(reminderStatsProvider);

    String? name;
    String? email;
    String? avatarUrl;

    if (authState is AuthAuthenticated) {
      name = authState.auth.user.name;
      email = authState.auth.user.email;
      avatarUrl = authState.auth.user.avatarUrl;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          // Avatar + Info
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surface,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              (name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.black, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name ?? 'Usuário',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: statsAsync.when(
              data: (stats) => Row(
                children: [
                  _StatItem(label: 'Total', value: '${stats['total'] ?? 0}'),
                  _StatDivider(),
                  _StatItem(label: 'Enviados', value: '${stats['sent'] ?? 0}'),
                  _StatDivider(),
                  _StatItem(
                      label: 'Pendentes', value: '${stats['pending'] ?? 0}'),
                ],
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Menu items
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Editar perfil',
            onTap: () => _showEditProfile(context, ref, name),
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notificações',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacidade',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.info_outline,
            label: 'Sobre o CineAlert',
            onTap: () => _showAbout(context),
          ),

          const Divider(),

          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Sair',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Tem certeza que deseja sair da conta?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Não')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                context.goNamed('login');
              }
            },
            color: AppColors.error,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showEditProfile(
      BuildContext context, WidgetRef ref, String? currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil atualizado!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CineAlert'),
        content: const Text(
          'CineAlert v1.0.0\n\nO app de lembretes de filmes e séries.\n\nPowered by IMDB via RapidAPI.',
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 8);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: c, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textDisabled, size: 20),
      onTap: onTap,
    );
  }
}
