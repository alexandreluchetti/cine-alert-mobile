import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_theme.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Initialize notifications
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // App-level error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== App-level Exception ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== Platform-level Exception ===');
    debugPrint(error.toString());
    debugPrint(stack.toString());
    return true;
  };

  runApp(const ProviderScope(child: CineAlertApp()));
}

class CineAlertApp extends ConsumerWidget {
  const CineAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'CineAlert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
