
import 'package:flutter_test/flutter_test.dart';
import 'package:rebsspace/main.dart';

void main() {
  testWidgets('REBS HRMS app starts successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
