import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_theme.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('=== App Startup: Starting Initializations ===');
  
  try {
    // Initialize Firebase
    debugPrint('=== App Startup: Initializing Firebase ===');
    await Firebase.initializeApp();
    debugPrint('=== App Startup: Firebase Initialized ===');
  } catch (e) {
    debugPrint('=== App Startup: Firebase Initialization Failed: $e ===');
  }
  
  await initializeDateFormatting('pt_BR', null);

  try {
    // Initialize notifications
    debugPrint('=== App Startup: Initializing Notifications ===');
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
    debugPrint('=== App Startup: Notifications Initialized ===');
  } catch (e) {
    debugPrint('=== App Startup: Notification Initialization Failed: $e ===');
  }

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
