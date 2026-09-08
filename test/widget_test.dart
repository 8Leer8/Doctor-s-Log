import 'package:flutter_test/flutter_test.dart';
import 'package:arknight_reader/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ArknightReaderApp());
    expect(find.text('LIBRARY'), findsOneWidget);
  });
}
