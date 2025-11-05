import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sana_app/core/config/app_config.dart';
import 'package:sana_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize app configuration
  await AppConfig.initialize();

  // Run app with Riverpod
  runApp(
    const ProviderScope(
      child: SanaApp(),
    ),
  );
}
