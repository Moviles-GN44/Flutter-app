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
}
