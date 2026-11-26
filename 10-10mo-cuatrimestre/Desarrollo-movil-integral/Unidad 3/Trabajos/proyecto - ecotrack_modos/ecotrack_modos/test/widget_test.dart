import 'package:flutter_test/flutter_test.dart';
import 'package:ecotrack_modos/main.dart';

void main() {
  testWidgets('muestra el panel de modos', (tester) async {
    await tester.pumpWidget(const EcoTrackModosApp());
    expect(find.textContaining('Modos de compilación'), findsOneWidget);
  });
}
