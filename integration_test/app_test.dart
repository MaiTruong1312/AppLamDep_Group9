import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:applamdep/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App khởi động và nhấn nút tăng', (tester) async {
    app.main(); // chạy app
    await tester.pumpAndSettle();

    // Kiểm tra giá trị ban đầu
    expect(find.text('0'), findsOneWidget);

    // Nhấn nút "+"
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Kiểm tra kết quả sau khi nhấn
    expect(find.text('1'), findsOneWidget);
  });
}
