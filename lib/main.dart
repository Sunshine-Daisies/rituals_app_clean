import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart'; // Ensure Auth Service is imported effectively before usage
import 'features/settings/services/settings_service.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file FIRST
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Failed to load .env file: $e');
  }

  // Initialize App Configuration
  // appConfig.autoDetect();
  appConfig.printConfig();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // Initialize Auth
  await AuthService.init();

  // Initialize Notifications (after auth)
  try {
    await NotificationService().initialize();
    print('NotificationService initialized');
  } catch (e) {
    print('Failed to initialize NotificationService: $e');
  }

  // Initialize Settings
  await SettingsService().init();

  runApp(const ProviderScope(child: RitualsApp()));
}

class RitualsApp extends ConsumerWidget {
  const RitualsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Personalized Daily Rituals',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
