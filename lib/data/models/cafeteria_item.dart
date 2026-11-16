import 'dart:convert';

class CafeteriaItemModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'Breakfast', 'Lunch', 'Bowls', 'Beverages', 'Bakery'
  final double price; // in meal credits
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<String>
  dietaryTags; // 'Vegetarian', 'Vegan', 'Halal', 'Gluten-Free', 'High-Protein'
  final String
  diningHall; // 'Turing Bistro', 'Hopper Tech Eatery', 'Lovelace Cafe'
  final String operationalHours;
  final bool isAvailable;
  final String imageAsset;

  const CafeteriaItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.dietaryTags,
    required this.diningHall,
    required this.operationalHours,
    this.isAvailable = true,
    required this.imageAsset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'dietary_tags': jsonEncode(dietaryTags),
      'dining_hall': diningHall,
      'operational_hours': operationalHours,
      'is_available': isAvailable ? 1 : 0,
      'image_asset': imageAsset,
    };
  }

  factory CafeteriaItemModel.fromMap(Map<String, dynamic> map) {
    List<String> tags = [];
    final rawTags = map['dietary_tags'];
    if (rawTags is String) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) {
          tags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        tags = [];
      }
    } else if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }

    return CafeteriaItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      calories: (map['calories'] as num).toInt(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      dietaryTags: tags,
      diningHall: map['dining_hall'] as String,
      operationalHours: map['operational_hours'] as String,
      isAvailable: (map['is_available'] as num?)?.toInt() == 1,
      imageAsset:
          (map['image_asset'] as String?) ?? 'assets/images/meal_default.png',
    );
  }

  CafeteriaItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    List<String>? dietaryTags,
    String? diningHall,
    String? operationalHours,
    bool? isAvailable,
    String? imageAsset,
  }) {
    return CafeteriaItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      diningHall: diningHall ?? this.diningHall,
      operationalHours: operationalHours ?? this.operationalHours,
      isAvailable: isAvailable ?? this.isAvailable,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}
