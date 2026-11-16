import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/cafeteria_repository.dart';
import 'package:cityzens_app/presentation/cafeteria/cafeteria_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('CafeteriaProvider & Repository Business Logic Tests', () {
    late CafeteriaRepository repository;
    late CafeteriaProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = CafeteriaRepository(database: db);
      provider = CafeteriaProvider(repository: repository);
    });

    test(
      'Initializes with default student wallet balance and menu items',
      () async {
        await provider.loadData();

        expect(provider.allMenuItems.isNotEmpty, true);
        expect(provider.wallet, isNotNull);
        expect(provider.wallet!.studentId, 'CTZ-2026-8842');
        expect(provider.wallet!.balance, 150.00);
        expect(provider.wallet!.rewardPoints, 320);
        expect(provider.orderHistory.isNotEmpty, true);
      },
    );

    test(
      'Filters menu catalog by dining hall and dietary preferences',
      () async {
        await provider.loadData();

        // Filter by Turing Bistro
        provider.selectDiningHall('Turing Bistro');
        for (final item in provider.filteredMenuItems) {
          expect(item.diningHall, 'Turing Bistro');
        }

        // Filter by Vegetarian
        provider.selectDiningHall('All Halls');
        provider.toggleDietaryFilter('Vegetarian');
        for (final item in provider.filteredMenuItems) {
          expect(item.dietaryTags.contains('Vegetarian'), true);
        }
      },
    );

    test(
      'Search query matches item name or description case-insensitively',
      () async {
        await provider.loadData();

        provider.setSearchQuery('quinoa');
        expect(provider.filteredMenuItems.isNotEmpty, true);
        expect(
          provider.filteredMenuItems.first.name.toLowerCase().contains(
            'quinoa',
          ),
          true,
        );

        provider.setSearchQuery('UNKNOWN_DISH_XYZ');
        expect(provider.filteredMenuItems, isEmpty);
      },
    );

    test('Cart accurately calculates subtotal and aggregated macronutrient profile', () async {
      await provider.loadData();

      final item1 = provider.allMenuItems.firstWhere(
        (i) => i.id == 'meal_tb_01',
      );
      final item2 = provider.allMenuItems.firstWhere(
        (i) => i.id == 'meal_tb_02',
      );

      provider.addToCart(item1, quantity: 2);
      provider.addToCart(item2, quantity: 1);

      expect(provider.cartItemCount, 3);
      final expectedSubtotal = (item1.price * 2) + item2.price;
      expect(provider.cartSubtotal, closeTo(expectedSubtotal, 0.01));

      final expectedCalories = (item1.calories * 2) + item2.calories;
      expect(provider.cartTotalCalories, expectedCalories);

      final expectedProtein = (item1.proteinG * 2) + item2.proteinG;
      expect(provider.cartTotalProteinG, closeTo(expectedProtein, 0.01));
    });

    test('Pre-order placement deducts meal credits and generates simulated NFC token', () async {
      await provider.loadData();

      final initialBalance = provider.wallet!.balance;
      final item = provider.allMenuItems.first;

      provider.addToCart(item, quantity: 1);
      provider.toggleAllergy('Gluten');
      provider.setCustomAllergyNote('Extra crispy please');
      provider.setPickupTime('30 mins');
      provider.setPaymentMethod('NFC Tap-to-Pay');

      final success = await provider.placeOrder();
      expect(success, true);
      expect(provider.cart, isEmpty);
      expect(provider.lastConfirmedOrder, isNotNull);
      expect(provider.lastConfirmedOrder!.nfcToken.startsWith('NFC-TX-'), true);
      expect(
        provider.lastConfirmedOrder!.allergyFlags.contains('Gluten'),
        true,
      );
      expect(
        provider.wallet!.balance,
        closeTo(initialBalance - item.price, 0.01),
      );
      expect(provider.wallet!.rewardPoints, greaterThan(320));
    });

    test('Insufficient meal credits balance guards order placement', () async {
      await provider.loadData();

      final item = provider.allMenuItems.first;
      // Add 40 items so total exceeds $150
      provider.addToCart(item, quantity: 40);

      expect(provider.canAffordCart, false);
      final success = await provider.placeOrder();
      expect(success, false);
      expect(provider.errorMessage, contains('Insufficient meal credits'));
    });

    test(
      'Reloading meal credits deposits balance into SQLite wallet',
      () async {
        await provider.loadData();

        final initialBalance = provider.wallet!.balance;
        await provider.reloadCredits(50.0);

        expect(provider.wallet!.balance, closeTo(initialBalance + 50.0, 0.01));
      },
    );

    test('Cancelling confirmed order refunds meal credits to wallet', () async {
      await provider.loadData();

      final item = provider.allMenuItems.first;
      provider.addToCart(item, quantity: 1);
      await provider.placeOrder();

      final balanceAfterOrder = provider.wallet!.balance;
      final orderId = provider.lastConfirmedOrder!.id;

      final cancelled = await provider.cancelOrder(orderId);
      expect(cancelled, true);
      expect(
        provider.wallet!.balance,
        closeTo(balanceAfterOrder + item.price, 0.01),
      );
    });
  });
}
