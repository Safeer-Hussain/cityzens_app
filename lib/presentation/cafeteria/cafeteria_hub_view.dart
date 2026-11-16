import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/cafeteria_item.dart';
import 'cafeteria_provider.dart';
import 'widgets/cafeteria_cart_sheet.dart';
import 'widgets/cafeteria_order_history_sheet.dart';

class CafeteriaHubView extends StatefulWidget {
  const CafeteriaHubView({super.key});

  @override
  State<CafeteriaHubView> createState() => _CafeteriaHubViewState();
}

class _CafeteriaHubViewState extends State<CafeteriaHubView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _portraitScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CafeteriaProvider>();
      if (provider.allMenuItems.isEmpty) {
        provider.loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _portraitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
        child: AppBar(
          toolbarHeight: isLandscape ? 36.0 : 48.0,
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              size: isLandscape ? 18 : 22,
              color: colors.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Smart Cafeteria & Meal Credits',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: isLandscape ? 13 : 16,
            ),
          ),
          actions: [
            // Order History Action
            IconButton(
              tooltip: 'Pre-Order History',
              icon: Icon(
                Icons.history_rounded,
                size: isLandscape ? 16 : 20,
                color: colors.primary,
              ),
              onPressed: () => _openOrderHistory(context),
            ),
            // Wallet Reload Button
            Consumer<CafeteriaProvider>(
              builder: (context, provider, _) {
                final balance = provider.wallet?.balance ?? 150.00;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: colors.onSecondaryContainer,
                    ),
                    label: Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    backgroundColor: colors.secondaryContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _showReloadDialog(context, provider),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<CafeteriaProvider>(
        builder: (context, provider, _) {
          final count = provider.cartItemCount;
          return FloatingActionButton.extended(
            heroTag: 'fab_cafeteria_cart',
            onPressed: () => _openCartSheet(context),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.shopping_basket_outlined, size: 20),
            ),
            label: Text(
              count > 0
                  ? 'Pre-Order (\$${provider.cartSubtotal.toStringAsFixed(2)})'
                  : 'Pre-Order Tray',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
      body: Consumer<CafeteriaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allMenuItems.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          if (isLandscape) {
            return _buildLandscapeLayout(context, provider, colors);
          }

          return _buildPortraitLayout(context, provider, colors);
        },
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Left Master Pane: Filters & Dining Halls
        SizedBox(
          width: 270,
          child: SingleChildScrollView(
            controller: _leftScrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDiningHallsSelector(provider, colors),
                const SizedBox(height: 10),
                _buildCategorySelector(provider, colors),
                const SizedBox(height: 10),
                _buildDietaryFilterChips(provider, colors),
                const SizedBox(height: 12),
                _buildWalletCard(context, provider, colors),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: colors.outlineVariant),

        // Right Detail Pane: Search & Menu Items
        Expanded(
          child: SingleChildScrollView(
            controller: _rightScrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(provider, colors),
                const SizedBox(height: 10),
                _buildMacroHeaderBanner(provider, colors),
                const SizedBox(height: 10),
                _buildMenuItemsGrid(context, provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return SingleChildScrollView(
      controller: _portraitScrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDiningHallsSelector(provider, colors),
          const SizedBox(height: 10),
          _buildCategorySelector(provider, colors),
          const SizedBox(height: 10),
          _buildDietaryFilterChips(provider, colors),
          const SizedBox(height: 10),
          _buildSearchBar(provider, colors),
          const SizedBox(height: 10),
          _buildWalletCard(context, provider, colors),
          const SizedBox(height: 12),
          _buildMacroHeaderBanner(provider, colors),
          const SizedBox(height: 10),
          _buildMenuItemsGrid(context, provider, colors),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDiningHallsSelector(
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAMPUS DINING HALL',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CafeteriaProvider.diningHalls.map((hall) {
            final isSelected = provider.selectedDiningHall == hall;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => provider.selectDiningHall(hall),
              label: Text(hall),
              labelStyle: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              backgroundColor: colors.surfaceContainer,
              selectedColor: colors.primary,
              side: BorderSide(
                color: isSelected ? colors.primary : colors.outlineVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEAL CATEGORY',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CafeteriaProvider.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = CafeteriaProvider.categories[index];
              final isSelected = provider.selectedCategory == cat;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => provider.selectCategory(cat),
                label: Text(cat),
                labelStyle: TextStyle(
                  color: isSelected ? colors.onSecondary : colors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
                backgroundColor: colors.surfaceContainer,
                selectedColor: colors.secondary,
                side: BorderSide(
                  color: isSelected ? colors.secondary : colors.outlineVariant,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryFilterChips(
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIETARY PREFERENCES',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CafeteriaProvider.availableDietaryTags.map((tag) {
            final isSelected = provider.activeDietaryFilter == tag;
            return FilterChip(
              selected: isSelected,
              onSelected: (_) => provider.toggleDietaryFilter(tag),
              avatar: Icon(
                Icons.check_circle_outline,
                size: 12,
                color: isSelected ? colors.onTertiary : colors.tertiary,
              ),
              label: Text(tag),
              labelStyle: TextStyle(
                color: isSelected ? colors.onTertiary : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
              backgroundColor: colors.surfaceContainer,
              selectedColor: colors.tertiary,
              side: BorderSide(
                color: isSelected ? colors.tertiary : colors.outlineVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(CafeteriaProvider provider, ColorScheme colors) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => provider.setSearchQuery(val),
      decoration: InputDecoration(
        hintText: 'Search quinoa bowls, protein wraps, matcha...',
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    final wallet = provider.wallet;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Credits Debit',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${wallet?.balance.toStringAsFixed(2) ?? '150.00'} Credits',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showReloadDialog(context, provider),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Reload', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroHeaderBanner(
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: 15,
                  color: colors.secondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Menu Items (${provider.filteredMenuItems.length})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Macro Verified',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsGrid(
    BuildContext context,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    final items = provider.filteredMenuItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 32,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No culinary items match your criteria',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing filters or search queries.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return _buildMenuItemCard(context, item, provider, colors);
      }).toList(),
    );
  }

  Widget _buildMenuItemCard(
    BuildContext context,
    CafeteriaItemModel item,
    CafeteriaProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Dining Hall & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.diningHall.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${item.price.toStringAsFixed(2)} Credits',
                style: TextStyle(
                  color: colors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title & Description
          Text(
            item.name,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.description,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Macronutrient Pills
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildMacroPill('${item.calories} kcal', colors.primary, colors),
              _buildMacroPill(
                '${item.proteinG.toStringAsFixed(0)}g Protein',
                colors.secondary,
                colors,
              ),
              _buildMacroPill(
                '${item.carbsG.toStringAsFixed(0)}g Carbs',
                colors.tertiary,
                colors,
              ),
              _buildMacroPill(
                '${item.fatG.toStringAsFixed(0)}g Fat',
                colors.error,
                colors,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dietary tags & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.dietaryTags.join(' • '),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  provider.addToCart(item);
                  AppFeedback.showSuccess(
                    context,
                    'Added "${item.name}" to pre-order tray.',
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                label: const Text(
                  'Add to Tray',
                  style: TextStyle(fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String text, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  void _openCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CafeteriaCartSheet(),
    );
  }

  void _openOrderHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CafeteriaOrderHistorySheet(),
    );
  }

  void _showReloadDialog(BuildContext context, CafeteriaProvider provider) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Reload Meal Credits',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select credit amount to deposit into your campus student wallet ledger:',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [25.0, 50.0, 100.0].map((amt) {
                  return FilledButton.tonal(
                    onPressed: () async {
                      await provider.reloadCredits(amt);
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                        AppFeedback.showSuccess(
                          context,
                          'Deposited \$${amt.toStringAsFixed(2)} credits to wallet.',
                        );
                      }
                    },
                    child: Text('+\$${amt.toInt()}'),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }
}
