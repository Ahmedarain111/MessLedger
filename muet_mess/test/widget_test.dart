import 'package:flutter_test/flutter_test.dart';
import 'package:mess_ledger/app.dart';
import 'package:mess_ledger/providers/auth_provider.dart';
import 'package:mess_ledger/providers/theme_provider.dart';

void main() {
  testWidgets('app boots properly', (tester) async {
    final auth = AuthProvider();
    final theme = ThemeProvider();
    await tester.pumpWidget(MessKhataApp(auth: auth, theme: theme));
    await tester.pump();
    expect(find.byType(MessKhataApp), findsOneWidget);
  });
}
