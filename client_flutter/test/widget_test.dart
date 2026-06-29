import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/main.dart';

void main() {
  testWidgets('E-Commerce app mounts and displays shop name header', (WidgetTester tester) async {
    // Pump the app
    await tester.pumpWidget(const ECommerceApp(useLiveConnection: false));

    // Verify that the title / shop name is displayed
    expect(find.text('STUDIO ESSENTIALS'), findsOneWidget);
  });

  testWidgets('E-Commerce app displays mock products in catalog feed', (WidgetTester tester) async {
    // Adjust surface size so all grid items are loaded and visible in test tree
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    // Pump the app
    await tester.pumpWidget(const ECommerceApp(useLiveConnection: false));

    // Verify all mock product names exist in the catalog feed
    expect(find.text('Studio Headset Mono'), findsOneWidget);
    expect(find.text('Minimalist Commuter Pack'), findsOneWidget);
    expect(find.text('Mechanical Keyboard 60%'), findsOneWidget);
    expect(find.text('Anodized Desk Lamp'), findsOneWidget);

    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Clicking a product card opens a bottom sheet with detailed description', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    
    // Pump the app
    await tester.pumpWidget(const ECommerceApp(useLiveConnection: false));

    // Tap on the first product (Studio Headset Mono)
    await tester.tap(find.text('Studio Headset Mono'));
    await tester.pumpAndSettle(); // Wait for bottom sheet animation to complete

    // Verify that description text inside the bottom sheet is present
    expect(find.text('Active noise cancelling wireless headset. Pure sound, architectural geometry.'), findsOneWidget);
    expect(find.text('ADD TO CART'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Adding product to cart updates shopping bag badge count', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    // Pump the app
    await tester.pumpWidget(const ECommerceApp(useLiveConnection: false));

    // Initially, badge should not be visible (cart is empty)
    expect(find.text('1'), findsNothing);

    // Tap the 'add' icon button for the first item (Studio Headset Mono)
    final addButtonFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Studio Headset Mono'),
        matching: find.byType(Container),
      ),
      matching: find.byIcon(Icons.add),
    );

    expect(addButtonFinder, findsOneWidget);
    await tester.tap(addButtonFinder);
    await tester.pump(); // trigger state rebuild

    // Verify badge showing count of '1' is displayed near the bag icon
    expect(find.text('1'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('E-Commerce app conditional flags render correctly when enabled', (WidgetTester tester) async {
    // Pump app with custom state mapping values
    await tester.pumpWidget(const MaterialApp(
      home: ECommerceDashboard(
        welcomeMessage: 'Special Welcome Greeting!',
        showSpecialOffer: true,
        showChatbot: true,
        useLiveConnection: false,
      ),
    ));

    // 1. Verify custom welcomeMessage is rendered
    expect(find.text('Special Welcome Greeting!'), findsOneWidget);

    // 2. Verify special offer banner is visible
    expect(find.text('SPECIAL OFFER: Use code ESSENTIALS20 for 20% off!'), findsOneWidget);

    // 3. Verify chatbot FAB is visible and triggers dialog
    final chatbotFinder = find.byType(FloatingActionButton);
    expect(chatbotFinder, findsOneWidget);

    await tester.tap(chatbotFinder);
    await tester.pumpAndSettle();

    expect(find.text('SHOP ASSISTANT'), findsOneWidget);
    expect(find.text('Hello! How can I assist you with your order today?'), findsOneWidget);
  });
}
