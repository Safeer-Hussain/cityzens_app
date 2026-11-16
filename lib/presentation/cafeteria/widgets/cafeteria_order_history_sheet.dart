import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/cafeteria_order.dart';
import '../cafeteria_provider.dart';
import 'nfc_receipt_dialog.dart';

class CafeteriaOrderHistorySheet extends StatelessWidget {
  const CafeteriaOrderHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<CafeteriaProvider>(
      builder: (context, provider, _) {
        final history = provider.orderHistory;

        return Container(
          constraints: BoxConstraints(
            maxHeight: isLandscape
                ? MediaQuery.of(context).size.height * 0.95
                : MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pre-Order History & NFC Receipts',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.outlineVariant, height: 1),

                // Order History List
                if (history.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No pre-orders recorded yet.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = history[index];
                        return _buildOrderHistoryCard(
                          context,
                          order,
                          provider,
                          colors,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderHistoryCard(
    BuildContext context,
    CafeteriaOrderModel order,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    final statusColor = _getStatusColor(order.status, colors);
    final dateStr = DateTime.fromMillisecondsSinceEpoch(order.createdAt)
        .toString()
        .substring(0, 16);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderNumber}',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.diningHall} • Pickup: ${order.pickupTime}',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            dateStr,
            style: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items: ${order.items.map((i) => '${i.quantity}x ${i.item.name}').join(', ')}',
            style: TextStyle(color: colors.onSurface, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${order.finalAmount.toStringAsFixed(2)} Credits',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                children: [
                  if (order.status == 'confirmed')
                    TextButton(
                      onPressed: () async {
                        final ok = await provider.cancelOrder(order.id);
                        if (context.mounted && ok) {
                          AppFeedback.showInfo(
                            context,
                            'Order cancelled. Meal credits refunded to student wallet.',
                          );
                        }
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => NfcReceiptDialog(order: order),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 14),
                    label: const Text(
                      'View Receipt',
                      style: TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'ready':
      case 'collected':
        return colors.secondary;
      case 'preparing':
        return colors.tertiary;
      case 'cancelled':
        return colors.error;
      default:
        return colors.primary;
    }
  }
}
