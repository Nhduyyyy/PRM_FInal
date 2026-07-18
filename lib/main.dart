import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'state/auth_provider.dart';
import 'state/badges_provider.dart';
import 'state/goals_provider.dart';
import 'state/history_provider.dart';
import 'state/home_provider.dart';
import 'state/pedometer_provider.dart';
import 'state/profile_provider.dart';
import 'state/run_session_provider.dart';
import 'state/stats_provider.dart';
import 'state/training_plan_provider.dart';
import 'state/user_level_provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDateFormatting('vi');
  await NotificationService.instance.init();
  runApp(const RunTrackerApp());
}

class RunTrackerApp extends StatelessWidget {
  const RunTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
        ChangeNotifierProvider(create: (_) => BadgesProvider()),
        ChangeNotifierProvider(create: (_) => RunSessionProvider()),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => UserLevelProvider()),
        ChangeNotifierProvider(create: (_) => PedometerProvider()),
      ],
      child: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return MaterialApp(
            title: 'Run Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: profile.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
