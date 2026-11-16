import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/cafeteria_item.dart';
import '../models/cafeteria_order.dart';
import '../models/student_wallet.dart';

class CafeteriaRepository {
  final AppDatabase database;

  CafeteriaRepository({required this.database});

  Database get _db => database.db;

  Future<List<CafeteriaItemModel>> getMenuItems({
    String? diningHall,
    String? category,
  }) async {
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (diningHall != null && category != null) {
      whereClause = 'dining_hall = ? AND category = ?';
      whereArgs = [diningHall, category];
    } else if (diningHall != null) {
      whereClause = 'dining_hall = ?';
      whereArgs = [diningHall];
    } else if (category != null) {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final results = await _db.query(
      'cafeteria_menu_items',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'price ASC',
    );

    return results.map((m) => CafeteriaItemModel.fromMap(m)).toList();
  }

  Future<StudentWalletModel> getStudentWallet(String studentId) async {
    final results = await _db.query(
      'student_wallets',
      where: 'student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );

    if (results.isEmpty) {
      final defaultWallet = StudentWalletModel(
        studentId: studentId,
        balance: 150.00,
        rewardPoints: 320,
        lastReloadedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.insert('student_wallets', defaultWallet.toMap());
      return defaultWallet;
    }

    return StudentWalletModel.fromMap(results.first);
  }

  Future<StudentWalletModel> reloadWallet(
    String studentId,
    double amount,
  ) async {
    final current = await getStudentWallet(studentId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedBalance = current.balance + amount;
    final addedPoints = (amount * 2).toInt();

    await _db.update(
      'student_wallets',
      {
        'balance': updatedBalance,
        'reward_points': current.rewardPoints + addedPoints,
        'last_reloaded_at': now,
      },
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    return current.copyWith(
      balance: updatedBalance,
      rewardPoints: current.rewardPoints + addedPoints,
      lastReloadedAt: now,
    );
  }

  Future<CafeteriaOrderModel> placeOrder(CafeteriaOrderModel order) async {
    return await _db.transaction<CafeteriaOrderModel>((txn) async {
      final walletResults = await txn.query(
        'student_wallets',
        where: 'student_id = ?',
        whereArgs: [order.studentId],
        limit: 1,
      );

      if (walletResults.isEmpty) {
        throw StateError('Student wallet not initialized.');
      }

      final wallet = StudentWalletModel.fromMap(walletResults.first);
      if (wallet.balance < order.finalAmount) {
        throw StateError(
          'Insufficient meal credits balance (Required: \$${order.finalAmount.toStringAsFixed(2)}, Available: \$${wallet.balance.toStringAsFixed(2)}).',
        );
      }

      // 1. Deduct balance and credit reward points
      final newBalance = wallet.balance - order.finalAmount;
      final newPoints = wallet.rewardPoints + (order.finalAmount * 2).toInt();
      await txn.update(
        'student_wallets',
        {'balance': newBalance, 'reward_points': newPoints},
        where: 'student_id = ?',
        whereArgs: [order.studentId],
      );

      // 2. Insert order
      await txn.insert('cafeteria_orders', order.toMap());

      return order;
    });
  }

  Future<List<CafeteriaOrderModel>> getOrderHistory(String studentId) async {
    final results = await _db.query(
      'cafeteria_orders',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );

    return results.map((m) => CafeteriaOrderModel.fromMap(m)).toList();
  }

  Future<bool> cancelOrder(String orderId) async {
    return await _db.transaction<bool>((txn) async {
      final orderResults = await txn.query(
        'cafeteria_orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderResults.isEmpty) return false;
      final order = CafeteriaOrderModel.fromMap(orderResults.first);

      if (order.status != 'confirmed') {
        return false; // Order already in preparation or fulfilled
      }

      // Refund credits
      final walletResults = await txn.query(
        'student_wallets',
        where: 'student_id = ?',
        whereArgs: [order.studentId],
        limit: 1,
      );

      if (walletResults.isNotEmpty) {
        final wallet = StudentWalletModel.fromMap(walletResults.first);
        await txn.update(
          'student_wallets',
          {'balance': wallet.balance + order.finalAmount},
          where: 'student_id = ?',
          whereArgs: [order.studentId],
        );
      }

      await txn.update(
        'cafeteria_orders',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      return true;
    });
  }
}
