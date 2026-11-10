import 'package:flutter_test/flutter_test.dart';
import 'package:keel/main.dart';

void main() {
  testWidgets('KeelApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const KeelApp());
    expect(find.byType(KeelApp), findsOneWidget);
  });
}
