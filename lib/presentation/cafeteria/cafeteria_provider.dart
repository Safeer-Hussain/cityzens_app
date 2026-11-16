import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/cafeteria_item.dart';
import '../../data/models/cafeteria_order.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/student_wallet.dart';
import '../../data/repositories/cafeteria_repository.dart';

class CafeteriaProvider extends ChangeNotifier {
  final CafeteriaRepository repository;

  static const String studentId = 'CTZ-2026-8842';
  static const String studentName = 'Safeer Hussain';

  static const List<String> diningHalls = [
    'All Halls',
    'Turing Bistro',
    'Hopper Tech Eatery',
    'Lovelace Cafe',
  ];

  static const List<String> categories = [
    'All Categories',
    'Bowls',
    'Lunch',
    'Breakfast',
    'Beverages',
    'Bakery',
  ];

  static const List<String> availableDietaryTags = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Gluten-Free',
    'High-Protein',
    'Dairy-Free',
  ];

  static const List<String> commonAllergiesList = [
    'Peanuts',
    'Tree Nuts',
    'Dairy',
    'Gluten',
    'Shellfish',
    'Soy',
    'Eggs',
  ];

  bool _isLoading = false;
  List<CafeteriaItemModel> _allMenuItems = [];
  StudentWalletModel? _wallet;
  String _selectedDiningHall = 'All Halls';
  String _selectedCategory = 'All Categories';
  String? _activeDietaryFilter;
  String _searchQuery = '';

  // Cart & Pre-Order State
  final List<CartItemModel> _cart = [];
  final Set<String> _selectedAllergies = {};
  String _customAllergyNote = '';
  String _selectedPickupTime = '15 mins';
  String _paymentMethod = 'Meal Credits Debit';

  // Orders
  List<CafeteriaOrderModel> _orderHistory = [];
  CafeteriaOrderModel? _lastConfirmedOrder;
  String? _errorMessage;

  CafeteriaProvider({required this.repository});

  bool get isLoading => _isLoading;
  List<CafeteriaItemModel> get allMenuItems => _allMenuItems;
  StudentWalletModel? get wallet => _wallet;
  String get selectedDiningHall => _selectedDiningHall;
  String get selectedCategory => _selectedCategory;
  String? get activeDietaryFilter => _activeDietaryFilter;
  String get searchQuery => _searchQuery;

  List<CartItemModel> get cart => List.unmodifiable(_cart);
  Set<String> get selectedAllergies => Set.unmodifiable(_selectedAllergies);
  String get customAllergyNote => _customAllergyNote;
  String get selectedPickupTime => _selectedPickupTime;
  String get paymentMethod => _paymentMethod;

  List<CafeteriaOrderModel> get orderHistory => _orderHistory;
  CafeteriaOrderModel? get lastConfirmedOrder => _lastConfirmedOrder;
  String? get errorMessage => _errorMessage;

  int get cartItemCount => _cart.fold<int>(0, (sum, i) => sum + i.quantity);
  double get cartSubtotal =>
      _cart.fold<double>(0.0, (sum, i) => sum + i.subtotal);
  int get cartTotalCalories =>
      _cart.fold<int>(0, (sum, i) => sum + i.totalCalories);
  double get cartTotalProteinG =>
      _cart.fold<double>(0.0, (sum, i) => sum + i.totalProteinG);
  double get cartTotalCarbsG =>
      _cart.fold<double>(0.0, (sum, i) => sum + i.totalCarbsG);
  double get cartTotalFatG =>
      _cart.fold<double>(0.0, (sum, i) => sum + i.totalFatG);

  bool get canAffordCart => _wallet != null && _wallet!.balance >= cartSubtotal;

  List<CafeteriaItemModel> get filteredMenuItems {
    return _allMenuItems.where((item) {
      if (_selectedDiningHall != 'All Halls' &&
          item.diningHall != _selectedDiningHall) {
        return false;
      }
      if (_selectedCategory != 'All Categories' &&
          item.category != _selectedCategory) {
        return false;
      }
      if (_activeDietaryFilter != null &&
          !item.dietaryTags.contains(_activeDietaryFilter)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesDesc = item.description.toLowerCase().contains(query);
        final matchesTag = item.dietaryTags.any(
          (t) => t.toLowerCase().contains(query),
        );
        if (!matchesName && !matchesDesc && !matchesTag) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allMenuItems = await repository.getMenuItems();
      _wallet = await repository.getStudentWallet(studentId);
      _orderHistory = await repository.getOrderHistory(studentId);
    } catch (e) {
      _errorMessage = 'Failed to load cafeteria data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDiningHall(String hall) {
    if (_selectedDiningHall == hall) return;
    _selectedDiningHall = hall;
    notifyListeners();
  }

  void selectCategory(String cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    notifyListeners();
  }

  void toggleDietaryFilter(String tag) {
    if (_activeDietaryFilter == tag) {
      _activeDietaryFilter = null;
    } else {
      _activeDietaryFilter = tag;
    }
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void addToCart(
    CafeteriaItemModel item, {
    int quantity = 1,
    String specialInstructions = '',
  }) {
    final existingIndex = _cart.indexWhere((c) => c.item.id == item.id);
    if (existingIndex >= 0) {
      final current = _cart[existingIndex];
      _cart[existingIndex] = current.copyWith(
        quantity: current.quantity + quantity,
        specialInstructions: specialInstructions.isNotEmpty
            ? specialInstructions
            : current.specialInstructions,
      );
    } else {
      _cart.add(
        CartItemModel(
          item: item,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((c) => c.item.id == itemId);
    notifyListeners();
  }

  void updateCartQuantity(String itemId, int delta) {
    final index = _cart.indexWhere((c) => c.item.id == itemId);
    if (index >= 0) {
      final current = _cart[index];
      final newQuantity = current.quantity + delta;
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = current.copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedAllergies.clear();
    _customAllergyNote = '';
    notifyListeners();
  }

  void toggleAllergy(String allergy) {
    if (_selectedAllergies.contains(allergy)) {
      _selectedAllergies.remove(allergy);
    } else {
      _selectedAllergies.add(allergy);
    }
    notifyListeners();
  }

  void setCustomAllergyNote(String note) {
    _customAllergyNote = note;
    notifyListeners();
  }

  void setPickupTime(String time) {
    _selectedPickupTime = time;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<bool> placeOrder() async {
    if (_cart.isEmpty) {
      _errorMessage = 'Your pre-order cart is empty.';
      notifyListeners();
      return false;
    }

    if (!canAffordCart) {
      _errorMessage = 'Insufficient meal credits in student wallet.';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final randomToken =
          'NFC-TX-${Random().nextInt(9000) + 1000}-${now.millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
      final orderNumber = 'ORD-8842-${Random().nextInt(900) + 100}';

      // Pick target dining hall from first cart item or fallback
      final targetDiningHall = _cart.first.item.diningHall;

      final combinedAllergies = List<String>.from(_selectedAllergies);
      if (_customAllergyNote.trim().isNotEmpty) {
        combinedAllergies.add('Precaution: ${_customAllergyNote.trim()}');
      }

      final order = CafeteriaOrderModel(
        id: 'ord_${now.microsecondsSinceEpoch}_${Random().nextInt(1000)}',
        orderNumber: orderNumber,
        studentId: studentId,
        studentName: studentName,
        diningHall: targetDiningHall,
        items: List<CartItemModel>.from(_cart),
        subtotal: cartSubtotal,
        discount: 0.0,
        finalAmount: cartSubtotal,
        totalCalories: cartTotalCalories,
        totalProteinG: cartTotalProteinG,
        totalCarbsG: cartTotalCarbsG,
        totalFatG: cartTotalFatG,
        allergyFlags: combinedAllergies,
        specialInstructions: _customAllergyNote.trim(),
        status: 'confirmed',
        pickupTime: _selectedPickupTime,
        paymentMethod: _paymentMethod,
        nfcToken: randomToken,
        createdAt: now.millisecondsSinceEpoch,
      );

      final confirmedOrder = await repository.placeOrder(order);
      _lastConfirmedOrder = confirmedOrder;
      _cart.clear();
      _selectedAllergies.clear();
      _customAllergyNote = '';

      // Refresh wallet & history
      _wallet = await repository.getStudentWallet(studentId);
      _orderHistory = await repository.getOrderHistory(studentId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to place cafeteria order: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> reloadCredits(double amount) async {
    try {
      _wallet = await repository.reloadWallet(studentId, amount);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reload credits: $e';
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final success = await repository.cancelOrder(orderId);
      if (success) {
        _wallet = await repository.getStudentWallet(studentId);
        _orderHistory = await repository.getOrderHistory(studentId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to cancel order: $e';
      notifyListeners();
      return false;
    }
  }
}
