import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/main.dart';

void main() {
  testWidgets('FlagForge static app mounts and displays title', (WidgetTester tester) async {
    // Pump the app
    await tester.pumpWidget(const FlagForgeExampleApp());

    // Verify that the title or header is found
    expect(find.text('FLAGFORGE SHELL'), findsOneWidget);
  });

  testWidgets('UI visually transforms when client state changes', (WidgetTester tester) async {
    // Pump the app
    await tester.pumpWidget(const FlagForgeExampleApp());

    // Initially premium_theme should be false (Standard Client Card is shown)
    expect(find.text('📱 STANDARD CLIENT CARD'), findsOneWidget);
    expect(find.text('💎 PREMIUM CLIENT CARD'), findsNothing);

    // Pump for 3 seconds to fire the timer
    await tester.pump(const Duration(seconds: 3));

    // After 3 seconds, premium_theme is true, card switches to premium, and banner message updates
    expect(find.text('💎 PREMIUM CLIENT CARD'), findsOneWidget);
    expect(find.text('📱 STANDARD CLIENT CARD'), findsNothing);
    expect(find.text('UI successfully transformed via local client state update!'), findsOneWidget);
  });
}
