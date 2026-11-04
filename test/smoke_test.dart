import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyman/core/l10n/l10n.dart';
import 'package:moneyman/core/theme/app_colors.dart';
import 'package:moneyman/core/theme/app_text_styles.dart';
import 'package:moneyman/core/theme/app_theme.dart';
import 'package:moneyman/core/utils/calc_parser.dart';
import 'package:moneyman/core/utils/money.dart';
import 'package:moneyman/widgets/app_card.dart';
import 'package:moneyman/widgets/category_icon.dart';
import 'package:moneyman/widgets/amount_text.dart';
import 'package:moneyman/widgets/progress_widgets.dart';

void main() {
  setUp(() {
    Fmt.configure(
      symbolValue: '₹',
      code: 'INR',
      decimalDigits: 2,
      symbolPositionBefore: true,
      style: 'full',
      dateFormatPattern: 'dd/MM/yyyy',
      firstDay: 7,
      lang: 'en',
    );
  });

  test('money formatting uses tabular rupees and paise', () {
    expect(Fmt.money(123450), contains('1,234.50'));
    expect(Fmt.money(0), contains('0.00'));
    expect(Fmt.parseAmount('1,234.50'), 123450);
    expect(Fmt.parseAmount('₹250'), 25000);
  });

  test('calculator parser respects operator precedence', () {
    expect(CalcParser.evaluateToPaise('1200+300'), 150000);
    expect(CalcParser.evaluateToPaise('200*3'), 60000);
    expect(CalcParser.evaluateToPaise('1000-250'), 75000);
    expect(CalcParser.evaluateToPaise('(100+50)/3'), 5000);
    expect(CalcParser.evaluate('2+*3'), isNull);
  });

  testWidgets('hindi localisation swaps the tab labels', (tester) async {
    Fmt.configure(
      symbolValue: '₹',
      code: 'INR',
      decimalDigits: 2,
      symbolPositionBefore: true,
      style: 'full',
      dateFormatPattern: 'dd/MM/yyyy',
      firstDay: 7,
      lang: 'hi',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Text(tr(context, 'Home')),
        ),
      ),
    );
    expect(find.text('होम'), findsOneWidget);
    Fmt.configure(
      symbolValue: '₹',
      code: 'INR',
      decimalDigits: 2,
      symbolPositionBefore: true,
      style: 'full',
      dateFormatPattern: 'dd/MM/yyyy',
      firstDay: 7,
      lang: 'en',
    );
  });

  testWidgets('theme exposes the app palette to widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            expect(Theme.of(context).extension<AppPalette>(), isNotNull);
            return Scaffold(
              body: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Safe to spend', style: context.caption),
                    const AmountText(250000, size: 22),
                    const ProgressBar(value: 0.42),
                    const RoundedGlyph(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Safe to spend'), findsOneWidget);
  });

  testWidgets('dark theme with a premium pack builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(pack: ThemePack.packs.last),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
