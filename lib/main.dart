import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'providers/app_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/auth_check_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RoutinePlusApp());
}

class RoutinePlusApp extends StatefulWidget {
  const RoutinePlusApp({super.key});

  @override
  State<RoutinePlusApp> createState() => _RoutinePlusAppState();
}

class _RoutinePlusAppState extends State<RoutinePlusApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // Initialize the app provider here where it's guaranteed to be available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.initialize();
          });

          return MaterialApp(
            title: 'Routine+',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/auth-check': (context) => const AuthCheckScreen(),
              '/auth': (context) => const AuthScreen(),
              '/home': (context) => const MainShell(),
            },
          );
        },
      ),
    );
  }
}
