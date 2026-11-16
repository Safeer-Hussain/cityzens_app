import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/cafeteria_repository.dart';
import 'package:cityzens_app/presentation/cafeteria/cafeteria_provider.dart';
import 'package:cityzens_app/presentation/cafeteria/cafeteria_hub_view.dart';

import '../helpers/test_database.dart';

void main() {
  group('CafeteriaHubView Widget & Viewport Safety Tests', () {
    late CafeteriaRepository repository;
    late CafeteriaProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = CafeteriaRepository(database: db);
      provider = CafeteriaProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CafeteriaProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme(), home: child),
      );
    }

    testWidgets(
      'Renders CafeteriaHubView with unique FAB heroTag fab_cafeteria_cart',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(child: const CafeteriaHubView()));
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.heroTag, equals('fab_cafeteria_cart'));
        expect(find.text('Smart Cafeteria & Meal Credits'), findsOneWidget);
        expect(find.text('CAMPUS DINING HALL'), findsOneWidget);
      },
    );

    testWidgets('Switching dining hall choice chip filters menu list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const CafeteriaHubView()));
      await tester.pumpAndSettle();

      provider.selectDiningHall('Turing Bistro');
      await tester.pumpAndSettle();

      expect(provider.selectedDiningHall, 'Turing Bistro');
      expect(find.text('Turing High-Protein Quinoa Bowl'), findsWidgets);
    });

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(child: const CafeteriaHubView()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('CAMPUS DINING HALL'), findsOneWidget);
        expect(find.text('MEAL CATEGORY'), findsOneWidget);
      },
    );

    testWidgets('Tapping Add to Tray increments cart item count', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const CafeteriaHubView()));
      await tester.pumpAndSettle();

      final addBtnFinder = find.widgetWithText(FilledButton, 'Add to Tray');
      expect(addBtnFinder, findsWidgets);

      await tester.tap(addBtnFinder.first);
      await tester.pumpAndSettle();

      expect(provider.cartItemCount, 1);
    });
  });
}
