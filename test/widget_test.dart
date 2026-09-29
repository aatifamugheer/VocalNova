import 'package:flutter_test/flutter_test.dart';

import 'package:vocalnova/main.dart';

void main() {
  testWidgets('VocalNova app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const VocalNovaApp());

    expect(find.text('VocalNova'), findsOneWidget);
  });
}