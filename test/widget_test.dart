import 'package:flutter_test/flutter_test.dart';
import 'package:do_an_tot_nghiep_ho_tro_nuoi_ong/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BeeGuardApp());
    await tester.pump();

    // Verify that splash screen shows BeeGuard title
    expect(find.text('BeeGuard'), findsOneWidget);
  });
}
