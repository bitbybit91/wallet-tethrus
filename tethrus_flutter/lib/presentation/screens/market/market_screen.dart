import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/offer.dart';
import '../../blocs/market/market_bloc.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  TradeType _selectedTradeType = TradeType.buy;
  String? _selectedPaymentMethod;
  String? _selectedFiatCurrency;

  @override
  void initState() {
    super.initState();
    context.read<MarketBloc>().add(const MarketLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTradeTypeChanged(TradeType type) {
    setState(() => _selectedTradeType = type);
    context.read<MarketBloc>().add(MarketFilterChanged(
          tradeType: type,
          paymentMethod: _selectedPaymentMethod,
          fiatCurrency: _selectedFiatCurrency,
        ));
  }

  void _onPaymentMethodSelected(String? method) {
    setState(() => _selectedPaymentMethod = method);
    context.read<MarketBloc>().add(MarketFilterChanged(
          tradeType: _selectedTradeType,
          paymentMethod: method,
          fiatCurrency: _selectedFiatCurrency,
        ));
  }

  void _onFiatCurrencySelected(String? currency) {
    setState(() => _selectedFiatCurrency = currency);
    context.read<MarketBloc>().add(MarketFilterChanged(
          tradeType: _selectedTradeType,
          paymentMethod: _selectedPaymentMethod,
          fiatCurrency: currency,
        ));
  }

  List<Offer> _filterBySearch(List<Offer> offers) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return offers;
    return offers.where((o) {
      return o.traderNickname.toLowerCase().contains(query) ||
          o.paymentMethod.toLowerCase().contains(query) ||
          o.fiatCurrency.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'P2P Market',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTradeTypeToggle(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildOfferList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/market/create-offer'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Offer',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTradeTypeToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Buy USDT',
              isActive: _selectedTradeType == TradeType.buy,
              activeColor: AppColors.buyAccent,
              onTap: () => _onTradeTypeChanged(TradeType.buy),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Sell USDT',
              isActive: _selectedTradeType == TradeType.sell,
              activeColor: AppColors.sellAccent,
              onTap: () => _onTradeTypeChanged(TradeType.sell),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by nickname, method...',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPaymentMethodChip(),
          const SizedBox(width: 8),
          _buildCurrencyChip(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip() {
    final isActive = _selectedPaymentMethod != null;
    return FilterChip(
      label: Text(
        _selectedPaymentMethod ?? 'Payment Method',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isActive,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.darkSurface,
      side: BorderSide(color: isActive ? AppColors.primary : AppColors.border),
      showCheckmark: false,
      onSelected: (_) {
        _showSelectionSheet(
          title: 'Payment Method',
          items: AppConstants.paymentMethods,
          selected: _selectedPaymentMethod,
          onSelected: _onPaymentMethodSelected,
        );
      },
    );
  }

  Widget _buildCurrencyChip() {
    final isActive = _selectedFiatCurrency != null;
    return FilterChip(
      label: Text(
        _selectedFiatCurrency ?? 'Currency',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isActive,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.darkSurface,
      side: BorderSide(color: isActive ? AppColors.primary : AppColors.border),
      showCheckmark: false,
      onSelected: (_) {
        _showSelectionSheet(
          title: 'Currency',
          items: AppConstants.supportedFiatCurrencies,
          selected: _selectedFiatCurrency,
          onSelected: _onFiatCurrencySelected,
        );
      },
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selected != null)
                    TextButton(
                      onPressed: () {
                        onSelected(null);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(color: AppColors.sellAccent),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = item == selected;
                  return ListTile(
                    title: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfferList() {
    return BlocBuilder<MarketBloc, MarketState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildShimmerList();
        }

        if (state.errorMessage != null && state.offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Failed to load offers',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context
                      .read<MarketBloc>()
                      .add(const MarketRefreshRequested()),
                  child: Text('Retry',
                      style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }

        final filtered = _filterBySearch(state.offers);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'No offers found',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async {
            context.read<MarketBloc>().add(const MarketRefreshRequested());
            await context
                .read<MarketBloc>()
                .stream
                .firstWhere((s) => !s.isLoading);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  !state.hasReachedMax &&
                  !state.isLoadingMore) {
                context
                    .read<MarketBloc>()
                    .add(const MarketLoadMoreRequested());
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                return _OfferCard(
                  offer: filtered[index],
                  onTap: () =>
                      context.go('/market/offer/${filtered[index].id}'),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppColors.darkSurface,
      highlightColor: AppColors.darkSurfaceVariant,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;

  const _OfferCard({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuy = offer.tradeType == TradeType.buy;
    final accentColor = isBuy ? AppColors.buyAccent : AppColors.sellAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Online status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: offer.traderOnline
                        ? AppColors.online
                        : AppColors.offline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  offer.traderNickname,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(offer.traderRating * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isBuy ? 'BUY' : 'SELL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${offer.pricePerUsdt.toStringAsFixed(2)} ${offer.fiatCurrency}',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'per USDT',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.payment, offer.paymentMethod),
                const SizedBox(width: 8),
                _infoChip(
                  Icons.straighten,
                  '${offer.minAmount.toStringAsFixed(0)} – ${offer.maxAmount.toStringAsFixed(0)} ${offer.fiatCurrency}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
