import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_go/main.dart';

void main() {
  testWidgets('LaundryGo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaundryGoApp());

    expect(find.text('Welcome to LaundryGo!'), findsOneWidget);
  });
}
