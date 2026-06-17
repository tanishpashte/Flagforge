import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/main.dart';

void main() {
  testWidgets('FlagForge static app mounts and displays title', (WidgetTester tester) async {
    // Pump the app
    await tester.pumpWidget(const FlagForgeExampleApp());

    // Verify that the title or header is found
    expect(find.text('FLAGFORGE SHELL'), findsOneWidget);
  });
}
