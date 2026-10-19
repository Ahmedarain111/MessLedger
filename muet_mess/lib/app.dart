import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/student_provider.dart';
import 'providers/manager_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/dashboard_provider.dart';

class MessKhataApp extends StatefulWidget {
  const MessKhataApp({super.key, required this.auth, required this.theme});

  final AuthProvider auth;
  final ThemeProvider theme;

  @override
  State<MessKhataApp> createState() => _MessKhataAppState();
}

class _MessKhataAppState extends State<MessKhataApp> {
  late final _router = AppRouter.build(widget.auth);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.theme),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => ManagerProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp.router(
          title: 'University Mess Khata',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  final theme = ThemeProvider();
  await theme.load();
  await auth.restore();
  runApp(MessKhataApp(auth: auth, theme: theme));
}
