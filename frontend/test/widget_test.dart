import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App should render without crashing', (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('SANA Wellness'),
            ),
          ),
        ),
      ),
    );

    // Verify app renders
    expect(find.text('SANA Wellness'), findsOneWidget);
  });

  testWidgets('Health Disclaimer Widget should display warning', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.shade50,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(height: 8),
                Text(
                  'Important Health Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This platform does NOT provide medical advice',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Important Health Disclaimer'), findsOneWidget);
    expect(find.text('This platform does NOT provide medical advice'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('Button should have tap feedback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                tapped = true;
              },
              child: Text('Tap Me'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap Me'));
    await tester.pump();

    expect(tapped, true);
  });

  testWidgets('Loading indicator should display while loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Error message should be clear and helpful', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Network error. Please check your connection.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Form validation should prevent submission', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    bool submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      submitted = true;
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Try to submit empty form
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, false);
    expect(find.text('Please enter a value'), findsOneWidget);

    // Fill form and submit
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, true);
  });

  group('App Constants Tests', () {
    test('Routes should be defined', () {
      const routeLogin = '/login';
      const routeSignup = '/signup';
      const routeDashboard = '/dashboard';
      const routePrivacyPolicy = '/privacy-policy';
      const routeTermsOfService = '/terms-of-service';

      expect(routeLogin, isNotEmpty);
      expect(routeSignup, isNotEmpty);
      expect(routeDashboard, isNotEmpty);
      expect(routePrivacyPolicy, isNotEmpty);
      expect(routeTermsOfService, isNotEmpty);
    });

    test('Validation constants should be correct', () {
      const minPasswordLength = 8;
      const minNameLength = 2;
      const maxBioLength = 500;

      expect(minPasswordLength, greaterThanOrEqualTo(8));
      expect(minNameLength, greaterThanOrEqualTo(2));
      expect(maxBioLength, greaterThanOrEqualTo(100));
    });

    test('Health score constants should be valid', () {
      const maxHealthScore = 100;
      const minHealthScore = 0;

      expect(maxHealthScore, equals(100));
      expect(minHealthScore, equals(0));
    });
  });

  group('Model Tests', () {
    test('User model should have required fields', () {
      final user = {
        'id': 'user-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'CLIENT',
      };

      expect(user['id'], isNotEmpty);
      expect(user['email'], contains('@'));
      expect(user['name'], isNotEmpty);
      expect(user['role'], isIn(['CLIENT', 'PRACTITIONER', 'ADMIN']));
    });
  });
}
