import 'cafeteria_item.dart';

class CartItemModel {
  final CafeteriaItemModel item;
  final int quantity;
  final String specialInstructions;

  const CartItemModel({
    required this.item,
    this.quantity = 1,
    this.specialInstructions = '',
  });

  double get subtotal => item.price * quantity;
  int get totalCalories => item.calories * quantity;
  double get totalProteinG => item.proteinG * quantity;
  double get totalCarbsG => item.carbsG * quantity;
  double get totalFatG => item.fatG * quantity;

  CartItemModel copyWith({
    CafeteriaItemModel? item,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'quantity': quantity,
      'special_instructions': specialInstructions,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      item: CafeteriaItemModel.fromMap(map['item'] as Map<String, dynamic>),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      specialInstructions: (map['special_instructions'] as String?) ?? '',
    );
  }
}
