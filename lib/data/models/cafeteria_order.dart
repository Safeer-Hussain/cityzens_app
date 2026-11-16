import 'dart:convert';

import 'cart_item.dart';

class CafeteriaOrderModel {
  final String id;
  final String orderNumber;
  final String studentId;
  final String studentName;
  final String diningHall;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double finalAmount;
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final List<String> allergyFlags;
  final String specialInstructions;
  final String status; // 'confirmed', 'preparing', 'ready', 'collected'
  final String pickupTime; // e.g. '12:45 PM'
  final String paymentMethod; // 'Meal Credits Debit', 'NFC Tap-to-Pay'
  final String nfcToken;
  final int createdAt;

  const CafeteriaOrderModel({
    required this.id,
    required this.orderNumber,
    required this.studentId,
    required this.studentName,
    required this.diningHall,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.finalAmount,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.allergyFlags,
    this.specialInstructions = '',
    this.status = 'confirmed',
    required this.pickupTime,
    required this.paymentMethod,
    required this.nfcToken,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'student_id': studentId,
      'student_name': studentName,
      'dining_hall': diningHall,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'subtotal': subtotal,
      'discount': discount,
      'final_amount': finalAmount,
      'total_calories': totalCalories,
      'total_protein_g': totalProteinG,
      'total_carbs_g': totalCarbsG,
      'total_fat_g': totalFatG,
      'allergy_flags': jsonEncode(allergyFlags),
      'special_instructions': specialInstructions,
      'status': status,
      'pickup_time': pickupTime,
      'payment_method': paymentMethod,
      'nfc_token': nfcToken,
      'created_at': createdAt,
    };
  }

  factory CafeteriaOrderModel.fromMap(Map<String, dynamic> map) {
    List<CartItemModel> parsedItems = [];
    final rawItems = map['items_json'];
    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          parsedItems = decoded
              .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        parsedItems = [];
      }
    }

    List<String> parsedAllergies = [];
    final rawAllergies = map['allergy_flags'];
    if (rawAllergies is String) {
      try {
        final decoded = jsonDecode(rawAllergies);
        if (decoded is List) {
          parsedAllergies = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedAllergies = [];
      }
    }

    return CafeteriaOrderModel(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      diningHall: map['dining_hall'] as String,
      items: parsedItems,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['final_amount'] as num).toDouble(),
      totalCalories: (map['total_calories'] as num?)?.toInt() ?? 0,
      totalProteinG: (map['total_protein_g'] as num?)?.toDouble() ?? 0.0,
      totalCarbsG: (map['total_carbs_g'] as num?)?.toDouble() ?? 0.0,
      totalFatG: (map['total_fat_g'] as num?)?.toDouble() ?? 0.0,
      allergyFlags: parsedAllergies,
      specialInstructions: (map['special_instructions'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'confirmed',
      pickupTime: map['pickup_time'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? 'Meal Credits Debit',
      nfcToken: map['nfc_token'] as String,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  CafeteriaOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? studentId,
    String? studentName,
    String? diningHall,
    List<CartItemModel>? items,
    double? subtotal,
    double? discount,
    double? finalAmount,
    int? totalCalories,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    List<String>? allergyFlags,
    String? specialInstructions,
    String? status,
    String? pickupTime,
    String? paymentMethod,
    String? nfcToken,
    int? createdAt,
  }) {
    return CafeteriaOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      diningHall: diningHall ?? this.diningHall,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      allergyFlags: allergyFlags ?? this.allergyFlags,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      status: status ?? this.status,
      pickupTime: pickupTime ?? this.pickupTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      nfcToken: nfcToken ?? this.nfcToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
