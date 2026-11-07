import 'package:flutter_test/flutter_test.dart';
import 'package:zuno/main.dart';

void main() {
  testWidgets('shows setup instructions when Supabase is not configured',
      (tester) async {
    await tester.pumpWidget(const ZunoApp(supabaseConfigured: false));
    expect(find.text('أكمل إعداد Supabase'), findsOneWidget);
  });
}
