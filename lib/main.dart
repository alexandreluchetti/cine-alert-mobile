import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
