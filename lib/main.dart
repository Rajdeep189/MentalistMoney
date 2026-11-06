import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Warm the local database before the first frame so the dashboard can render
  // real data immediately (offline-first: SQLite is the source of truth).
  await AppDatabase.instance.database;
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: MoneyManApp()));
}
