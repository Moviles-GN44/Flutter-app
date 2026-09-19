import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/main.dart';

void main() {
  testWidgets('Home shows the selected restaurant preview', (tester) async {
    await tester.pumpWidget(const UniandesFoodApp());

    expect(find.text('El Corral Uniandes'), findsWidgets);
    expect(find.text('View full menu'), findsOneWidget);
  });

  testWidgets('QR scan verifies the visit and opens the review form', (
    tester,
  ) async {
    await tester.pumpWidget(const UniandesFoodApp());

    await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scan QR code'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text('Visit verified!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('New review'), findsOneWidget);
    expect(find.text('VERIFIED VISIT'), findsOneWidget);
  });

  testWidgets('Restaurant detail switches between its three tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UniandesFoodApp());

    await tester.tap(find.text('View full menu'));
    await tester.pumpAndSettle();

    expect(find.text('Corral Todo Terreno'), findsOneWidget);
    expect(find.text(r'$24.900'), findsOneWidget);
    expect(find.text('Accepted payment methods'), findsOneWidget);

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('+57 300 555 0198'), findsOneWidget);

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    expect(find.text('187 Reviews'), findsOneWidget);
    expect(find.text('Camila G.'), findsOneWidget);
  });
}
