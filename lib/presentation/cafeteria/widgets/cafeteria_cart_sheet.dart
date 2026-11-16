import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../cafeteria_provider.dart';
import 'nfc_receipt_dialog.dart';

class CafeteriaCartSheet extends StatefulWidget {
  const CafeteriaCartSheet({super.key});

  @override
  State<CafeteriaCartSheet> createState() => _CafeteriaCartSheetState();
}

class _CafeteriaCartSheetState extends State<CafeteriaCartSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customAllergyController =
      TextEditingController();

  @override
  void dispose() {
    _customAllergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<CafeteriaProvider>(
      builder: (context, provider, _) {
        final cart = provider.cart;
        final wallet = provider.wallet;
        final subtotal = provider.cartSubtotal;
        final canAfford = provider.canAffordCart;

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
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pre-Order Tray (${provider.cartItemCount})',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (cart.isNotEmpty)
                        TextButton(
                          onPressed: () => provider.clearCart(),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: colors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(color: colors.outlineVariant, height: 1),

                // Cart Content Body
                if (cart.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 48,
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your pre-order tray is empty',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse dining hall menus and add nourishing meals.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cart Items List
                            ...cart.map((cartItem) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.item.name,
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cartItem.item.calories} kcal • ${cartItem.item.proteinG.toStringAsFixed(0)}g protein',
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${cartItem.item.price.toStringAsFixed(2)} credits each',
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton.filledTonal(
                                          iconSize: 14,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () =>
                                              provider.updateCartQuantity(
                                                cartItem.item.id,
                                                -1,
                                              ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            '${cartItem.quantity}',
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        IconButton.filledTonal(
                                          iconSize: 14,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () =>
                                              provider.updateCartQuantity(
                                                cartItem.item.id,
                                                1,
                                              ),
                                          icon: const Icon(Icons.add),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          iconSize: 16,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: colors.error,
                                          ),
                                          onPressed: () => provider
                                              .removeFromCart(cartItem.item.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 10),

                            // Total Macronutrient Preview
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL NUTRITION SUMMARY',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMacroTile(
                                        'Calories',
                                        '${provider.cartTotalCalories} kcal',
                                        colors.primary,
                                        colors,
                                      ),
                                      _buildMacroTile(
                                        'Protein',
                                        '${provider.cartTotalProteinG.toStringAsFixed(1)}g',
                                        colors.secondary,
                                        colors,
                                      ),
                                      _buildMacroTile(
                                        'Carbs',
                                        '${provider.cartTotalCarbsG.toStringAsFixed(1)}g',
                                        colors.tertiary,
                                        colors,
                                      ),
                                      _buildMacroTile(
                                        'Fat',
                                        '${provider.cartTotalFatG.toStringAsFixed(1)}g',
                                        colors.error,
                                        colors,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dietary Allergy Flags & Precaution Checklist
                            Text(
                              'DIETARY ALLERGY PRECAUTIONS',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select any allergy flags to alert dining kitchen staff.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: CafeteriaProvider.commonAllergiesList
                                  .map((allergy) {
                                    final isSelected = provider
                                        .selectedAllergies
                                        .contains(allergy);
                                    return FilterChip(
                                      selected: isSelected,
                                      onSelected: (_) =>
                                          provider.toggleAllergy(allergy),
                                      label: Text(allergy),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? colors.onTertiary
                                            : colors.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                      backgroundColor: colors.surfaceContainer,
                                      selectedColor: colors.tertiary,
                                      side: BorderSide(
                                        color: isSelected
                                            ? colors.tertiary
                                            : colors.outlineVariant,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            const SizedBox(height: 10),

                            // Custom Precaution Input
                            TextFormField(
                              controller: _customAllergyController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Custom Dietary Precaution (Optional)',
                                hintText: 'e.g. Severe peanut airborne allergy, no butter',
                              ),
                              onChanged: (val) =>
                                  provider.setCustomAllergyNote(val),
                              validator: (val) {
                                if (val != null && val.length > 120) {
                                  return 'Dietary note must be under 120 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Pickup ETA Selector
                            Text(
                              'PICKUP ESTIMATED TIME',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['15 mins', '30 mins', '45 mins'].map((
                                time,
                              ) {
                                final isSelected =
                                    provider.selectedPickupTime == time;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        provider.setPickupTime(time),
                                    label: Text(time),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? colors.onPrimary
                                          : colors.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                    backgroundColor: colors.surfaceContainer,
                                    selectedColor: colors.primary,
                                    side: BorderSide(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.outlineVariant,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Payment Method Selector
                            Text(
                              'PAYMENT PROTOCOL',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['Meal Credits Debit', 'NFC Tap-to-Pay']
                                  .map((method) {
                                    final isSelected =
                                        provider.paymentMethod == method;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        selected: isSelected,
                                        onSelected: (_) =>
                                            provider.setPaymentMethod(method),
                                        avatar: Icon(
                                          method.contains('NFC')
                                              ? Icons.nfc_rounded
                                              : Icons
                                                    .account_balance_wallet_outlined,
                                          size: 14,
                                          color: isSelected
                                              ? colors.onSecondary
                                              : colors.secondary,
                                        ),
                                        label: Text(method),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? colors.onSecondary
                                              : colors.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                        backgroundColor:
                                            colors.surfaceContainer,
                                        selectedColor: colors.secondary,
                                        side: BorderSide(
                                          color: isSelected
                                              ? colors.secondary
                                              : colors.outlineVariant,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            const SizedBox(height: 16),

                            // Student Wallet Balance Summary
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: canAfford
                                    ? colors.surfaceContainer
                                    : colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: canAfford
                                      ? colors.outlineVariant
                                      : colors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Wallet Balance Available',
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '\$${wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                                        style: TextStyle(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order Total',
                                        style: TextStyle(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '\$${subtotal.toStringAsFixed(2)} Credits',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!canAfford) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 14,
                                          color: colors.error,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Insufficient balance. Tap "Reload" to add credits.',
                                          style: TextStyle(
                                            color: colors.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Place Order Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: canAfford
                                    ? () => _handlePlaceOrder(context, provider)
                                    : null,
                                icon: Icon(
                                  provider.paymentMethod.contains('NFC')
                                      ? Icons.nfc_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  provider.paymentMethod.contains('NFC')
                                      ? 'Tap Phone to Authorize (\$${subtotal.toStringAsFixed(2)})'
                                      : 'Confirm Pre-Order (\$${subtotal.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePlaceOrder(
    BuildContext context,
    CafeteriaProvider provider,
  ) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await provider.placeOrder();
      if (context.mounted) {
        if (success && provider.lastConfirmedOrder != null) {
          Navigator.of(context).pop(); // Close cart sheet
          AppFeedback.showSuccess(
            context,
            'Pre-order confirmed. Meal credits deducted successfully.',
          );
          showDialog(
            context: context,
            builder: (_) =>
                NfcReceiptDialog(order: provider.lastConfirmedOrder!),
          );
        } else if (provider.errorMessage != null) {
          AppFeedback.showError(context, provider.errorMessage!);
        }
      }
    }
  }

  Widget _buildMacroTile(
    String label,
    String value,
    Color color,
    ColorScheme colors,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9),
        ),
      ],
    );
  }
}
