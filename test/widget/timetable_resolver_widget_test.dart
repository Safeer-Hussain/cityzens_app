import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/timetable_repository.dart';
import 'package:cityzens_app/presentation/timetable/timetable_provider.dart';
import 'package:cityzens_app/presentation/timetable/timetable_resolver_view.dart';
import 'package:cityzens_app/presentation/timetable/widgets/conflict_resolution_sheet.dart';
import 'package:cityzens_app/presentation/timetable/widgets/section_details_sheet.dart';

import '../helpers/test_database.dart';

void main() {
  group('TimetableResolverView Widget & Viewport Safety Tests', () {
    late TimetableRepository repository;
    late TimetableProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = TimetableRepository(database: db);
      provider = TimetableProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TimetableProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme(), home: child),
      );
    }

    testWidgets(
      'Renders TimetableResolverView with unique FAB heroTag fab_timetable_resolver',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const TimetableResolverView()),
        );
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.heroTag, equals('fab_timetable_resolver'));
        expect(
          find.text('Academic Timetable & Conflict Resolver'),
          findsOneWidget,
        );
        expect(find.textContaining('TIMETABLE CONFLICT'), findsOneWidget);
      },
    );

    testWidgets('Switching weekday tab updates selected day', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const TimetableResolverView()),
      );
      await tester.pumpAndSettle();

      // Tap Wednesday tab (day 3)
      final wedTab = find.text('Wed');
      expect(wedTab, findsOneWidget);
      await tester.tap(wedTab);
      await tester.pumpAndSettle();

      expect(provider.selectedDay, equals(3));
      expect(find.text('COURSE SCHEDULE FOR WEDNESDAY'), findsOneWidget);
    });

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const TimetableResolverView()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('TIMETABLE SCHEDULE'), findsOneWidget);
        expect(find.text('CONFLICT RADAR & HEURISTICS'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Resolve conflict FAB opens ConflictResolutionSheet modal',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const TimetableResolverView()),
        );
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.byType(ConflictResolutionSheet), findsOneWidget);
        expect(find.text('SCHEDULE OVERLAP DETECTED'), findsOneWidget);
        expect(find.textContaining('Min Overlap on'), findsOneWidget);
      },
    );

    testWidgets('Tapping course card opens SectionDetailsSheet modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const TimetableResolverView()),
      );
      await tester.pumpAndSettle();

      final courseCard = find.text('CS-401').first;
      await tester.tap(courseCard);
      await tester.pumpAndSettle();

      expect(find.byType(SectionDetailsSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SectionDetailsSheet),
          matching: find.text('Distributed Systems & Cloud Computing'),
        ),
        findsOneWidget,
      );
      expect(find.text('Drop Course Section'), findsOneWidget);
    });
  });
}
