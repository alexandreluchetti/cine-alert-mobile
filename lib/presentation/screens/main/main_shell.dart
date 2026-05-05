import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/reminder_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  /// Momento em que o app foi para background. Usado para calcular se o tempo
  /// em background ultrapassou o limiar e se é necessário atualizar os dados.
  DateTime? _pausedAt;

  /// Tempo mínimo em background para disparar a atualização dos providers.
  static const _refreshThreshold = Duration(minutes: 5);

  static const _routeNames = ['home', 'search', 'reminders', 'profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Registra o momento em que o app foi para background.
        // Não usar AppLifecycleState.inactive: ele dispara tanto ao entrar
        // em background quanto ao voltar ao foreground (em iOS e alguns
        // Android), o que zeraria _pausedAt exatamente antes de resumed.
        _pausedAt = DateTime.now();

      case AppLifecycleState.resumed:
        final paused = _pausedAt;
        if (paused != null &&
            DateTime.now().difference(paused) >= _refreshThreshold) {
          _onSessionRefresh();
        }

      default:
        break;
    }
  }

  /// Invalida os FutureProviders globais e emite o sinal de refresh para que
  /// as telas com estado próprio (ex.: RemindersScreen) possam se atualizar.
  void _onSessionRefresh() {
    ref.invalidate(trendingProvider);
    ref.invalidate(genresProvider);
    ref.invalidate(reminderStatsProvider);
    ref.read(sessionRefreshProvider.notifier).state++;
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    context.goNamed(_routeNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = switch (location) {
      var l when l.startsWith('/home') => 0,
      var l when l.startsWith('/search') => 1,
      var l when l.startsWith('/reminders') => 2,
      var l when l.startsWith('/profile') => 3,
      _ => 0,
    };
    if (idx != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = idx);
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Lembretes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
