import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'state/badges_provider.dart';
import 'state/goals_provider.dart';
import 'state/history_provider.dart';
import 'state/home_provider.dart';
import 'state/profile_provider.dart';
import 'state/run_session_provider.dart';
import 'state/stats_provider.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
        ChangeNotifierProvider(create: (_) => BadgesProvider()),
        ChangeNotifierProvider(create: (_) => RunSessionProvider()),
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
