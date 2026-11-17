import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/parking_repository.dart';
import 'package:cityzens_app/presentation/parking/parking_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('ParkingProvider & Repository Business Logic Tests', () {
    late ParkingRepository repository;
    late ParkingProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = ParkingRepository(database: db);
      provider = ParkingProvider(repository: repository);
    });

    test(
      'Initializes with seeded parking zones and active student permit',
      () async {
        await provider.loadData();

        expect(provider.zones.isNotEmpty, true);
        expect(provider.zones.length, equals(3));
        expect(provider.activePermit, isNotNull);
        expect(provider.activePermit!.vehiclePlate, equals('ABC-8842'));
        expect(provider.activePermit!.studentId, equals('CTZ-2026-8842'));
        expect(provider.activePermit!.rfidToken.startsWith('RFID-PK-'), true);
        expect(provider.evReservations.isNotEmpty, true);
      },
    );

    test('Calculates campus-wide occupancy rates correctly', () async {
      await provider.loadData();

      final totalSpots = provider.totalCampusSpots;
      final available = provider.availableCampusSpots;

      expect(totalSpots, equals(260 + 180 + 48)); // 488
      expect(available, lessThan(totalSpots));
      expect(provider.overallOccupancyRate, greaterThan(0.5));
      expect(provider.overallOccupancyRate, lessThanOrEqualTo(1.0));
      expect(provider.availableEvCampusSpots, greaterThan(0));
    });

    test(
      'Filters parking structures by covered, EV available, and search query',
      () async {
        await provider.loadData();

        // Filter by Covered
        provider.setFilter('Covered');
        for (final z in provider.filteredZones) {
          expect(z.isCovered, true);
        }

        // Filter by Fast Charging
        provider.setFilter('Fast Charging');
        for (final z in provider.filteredZones) {
          expect(
            z.chargerTypes.any(
              (c) => c.contains('Fast') || c.contains('150kW'),
            ),
            true,
          );
        }

        // Filter by Search Query
        provider.setFilter('All Lots');
        provider.setSearchQuery('Engineering');
        expect(provider.filteredZones.length, equals(1));
        expect(provider.filteredZones.first.name, contains('North Structure'));
      },
    );

    test(
      'Reserves EV charging bay and generates cryptographic queue token',
      () async {
        await provider.loadData();

        final initialReservations = provider.evReservations.length;
        final zone = provider.zones.firstWhere(
          (z) => z.id == 'zone_north_deck',
        );
        final initialFreeEv = zone.availableEvSpots;

        final success = await provider.reserveEvSlot(
          zoneId: 'zone_north_deck',
          stationId: 'ST-02',
          chargerType: 'DC Fast 50kW (CCS)',
          slotTime: '15:30 - 16:30',
          targetBatteryPercent: 90,
        );

        expect(success, true);
        expect(provider.evReservations.length, equals(initialReservations + 1));
        expect(provider.lastConfirmedReservation, isNotNull);
        expect(
          provider.lastConfirmedReservation!.queueToken.startsWith(
            'EV-QUEUE-#',
          ),
          true,
        );
        expect(
          provider.lastConfirmedReservation!.estimatedEnergyKwh,
          greaterThan(25.0),
        );
        expect(
          provider.lastConfirmedReservation!.costCredits,
          greaterThan(3.0),
        );

        final updatedZone = provider.zones.firstWhere(
          (z) => z.id == 'zone_north_deck',
        );
        expect(updatedZone.availableEvSpots, equals(initialFreeEv - 1));
      },
    );

    test(
      'Cancelling EV slot frees occupied spot on the parking zone',
      () async {
        await provider.loadData();

        // Create a reservation first
        await provider.reserveEvSlot(
          zoneId: 'zone_south_lot',
          stationId: 'ST-01',
          chargerType: 'Level 2 7.2kW (J1772)',
          slotTime: '14:00 - 15:00',
          targetBatteryPercent: 80,
        );

        final reservation = provider.lastConfirmedReservation!;
        final zoneAfterReserve = provider.zones.firstWhere(
          (z) => z.id == 'zone_south_lot',
        );
        final freeAfterReserve = zoneAfterReserve.availableEvSpots;

        final cancelSuccess = await provider.cancelReservation(reservation.id);
        expect(cancelSuccess, true);

        final zoneAfterCancel = provider.zones.firstWhere(
          (z) => z.id == 'zone_south_lot',
        );
        expect(zoneAfterCancel.availableEvSpots, equals(freeAfterReserve + 1));
      },
    );

    test(
      'Simulated camera OCR plate scanner matches active student permit',
      () async {
        await provider.loadData();

        // Matching plate
        provider.simulatePlateScan('ABC-8842');
        expect(provider.scannedPlate, equals('ABC-8842'));
        expect(provider.plateMatchesPermit, true);

        // External / Non-matching plate
        provider.simulatePlateScan('KPK-9120');
        expect(provider.scannedPlate, equals('KPK-9120'));
        expect(provider.plateMatchesPermit, false);

        // Clear scanner
        provider.clearScannedPlate();
        expect(provider.scannedPlate, isNull);
        expect(provider.plateMatchesPermit, false);
      },
    );

    test(
      'Renewing parking permit registers new permit and deactivates prior',
      () async {
        await provider.loadData();

        final success = await provider.renewPermit(
          vehiclePlate: 'LHR-7722',
          vehicleModel: 'Hyundai Ioniq 5 / Matte Gold',
          permitTier: 'Standard Semester Pass',
          assignedZone: 'North Structure Multilevel Deck',
          durationDays: 180,
        );

        expect(success, true);
        expect(provider.activePermit, isNotNull);
        expect(provider.activePermit!.vehiclePlate, equals('LHR-7722'));
        expect(provider.activePermit!.vehicleModel, contains('Hyundai Ioniq'));
        expect(provider.activePermit!.daysRemaining, greaterThan(150));
        expect(provider.activePermit!.rfidToken.startsWith('RFID-PK-'), true);
        expect(
          provider.activePermit!.barcodePayload,
          equals('CTZ-PRK-8842-LHR7722'),
        );
      },
    );
  });
}
