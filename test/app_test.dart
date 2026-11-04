import 'package:brainquiz/app.dart';
import 'package:brainquiz/ui/theme/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app is dark only and uses Nunito', (tester) async {
    await tester.pumpWidget(const TowerBuildApp(home: SizedBox()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme, isNull);
    expect(app.darkTheme!.brightness, Brightness.dark);
    expect(app.darkTheme!.scaffoldBackgroundColor, const Color(0xFF05070D));
    expect(app.title, 'Tower Build');
    expect(app.debugShowCheckedModeBanner, isFalse);
  });

  test('nunito sets the variable font weight', () {
    final s = nunito(18, weight: 900);
    expect(s.fontFamily, 'Nunito');
    expect(s.fontVariations, [const FontVariation('wght', 900)]);
    expect(s.fontWeight, FontWeight.w900);
  });
}
