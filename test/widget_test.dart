import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dosing_pump_app/main.dart';
import 'package:dosing_pump_app/providers/pump_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PumpProvider(),
        child: const MaterialApp(home: MainShell()),
      ),
    );
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
