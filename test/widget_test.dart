import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/db_service.dart';
import 'package:frontend/services/sms_parser_service.dart';
import 'package:frontend/services/ml_service_client.dart';

void main() {
  testWidgets('App initializes and renders Dashboard in mock mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProxyProvider<AuthService, DBService>(
            create: (_) => DBService(),
            update: (_, auth, db) {
              db!.setUserId(auth.currentUser?.uid);
              return db;
            },
          ),
          ChangeNotifierProvider(create: (_) => SMSParserService()),
          Provider(create: (_) => MLServiceClient()),
        ],
        child: const FinMateApp(),
      ),
    );

    // Re-render frame
    await tester.pump();

    // Verify we bypass login screen in mock dev mode and render dashboard header
    expect(find.textContaining('Nikhil Sharma'), findsOneWidget);
    expect(find.text('Here is your finance status today'), findsOneWidget);
    expect(find.textContaining('Financial Health'), findsOneWidget);
  });
}
