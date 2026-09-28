import 'package:flutter_test/flutter_test.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_app/main.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

void main() {
  testWidgets('shows the host and degrades without Rust', (tester) async {
    await Surface.init(const SurfaceConfig(appId: 'surfaces_app_test'));
    await tester.pumpWidget(const SurfacesApp(title: 'Test', home: HomePage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('No Rust core here'), findsOneWidget);
    expect(find.text('Count to 6'), findsOneWidget);
  });
}
