import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sana_app/core/config/app_config.dart';
import 'package:sana_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize app configuration
  await AppConfig.initialize();

  // Initialize Stripe
  // Note: Replace with your Stripe publishable key from environment or config
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_your_publishable_key_here',
  );
  await Stripe.instance.applySettings();

  // Run app with Riverpod
  runApp(
    const ProviderScope(
      child: SanaApp(),
    ),
  );
}
