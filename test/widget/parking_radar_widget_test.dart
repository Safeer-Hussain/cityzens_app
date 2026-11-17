import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/parking_repository.dart';
import 'package:cityzens_app/presentation/parking/parking_provider.dart';
import 'package:cityzens_app/presentation/parking/parking_radar_view.dart';
import 'package:cityzens_app/presentation/parking/widgets/ev_reservation_sheet.dart';
import 'package:cityzens_app/presentation/parking/widgets/plate_scanner_sheet.dart';

import '../helpers/test_database.dart';

void main() {
  group('ParkingRadarView Widget & Viewport Safety Tests', () {
    late ParkingRepository repository;
    late ParkingProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = ParkingRepository(database: db);
      provider = ParkingProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ParkingProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme(), home: child),
      );
    }

    testWidgets(
      'Renders ParkingRadarView with unique FAB heroTag fab_parking_radar',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(child: const ParkingRadarView()));
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.heroTag, equals('fab_parking_radar'));
        expect(find.text('Campus Parking & EV Radar'), findsOneWidget);
        expect(find.text('CAMPUS LOT OCCUPANCY'), findsOneWidget);
      },
    );

    testWidgets('Switching filter choice chip updates the zone list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ParkingRadarView()));
      await tester.pumpAndSettle();

      expect(find.text('North Structure Multilevel Deck'), findsWidgets);

      // Tap Covered chip
      final coveredChip = find.widgetWithText(ChoiceChip, 'Covered');
      expect(coveredChip, findsOneWidget);
      await tester.tap(coveredChip);
      await tester.pumpAndSettle();

      expect(provider.selectedFilter, equals('Covered'));
    });

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(child: const ParkingRadarView()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('CAMPUS PARKING RADAR'), findsOneWidget);
        expect(find.text('ACTIVE EV CHARGING QUEUE'), findsOneWidget);
      },
    );

    testWidgets('Tapping Reserve EV Slot FAB opens EvReservationSheet modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ParkingRadarView()));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(EvReservationSheet), findsOneWidget);
      expect(find.text('Reserve Charging Slot'), findsOneWidget);
    });

    testWidgets(
      'Tapping Camera scanner appbar action opens PlateScannerSheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestApp(child: const ParkingRadarView()));
        await tester.pumpAndSettle();

        final scannerAction = find.byTooltip('Camera Plate Scanner');
        expect(scannerAction, findsOneWidget);
        await tester.tap(scannerAction);
        await tester.pumpAndSettle();

        expect(find.byType(PlateScannerSheet), findsOneWidget);
        expect(find.text('License Plate Scanner'), findsOneWidget);
      },
    );
  });
}
