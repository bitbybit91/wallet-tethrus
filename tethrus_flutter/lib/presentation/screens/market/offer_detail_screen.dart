import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/offer.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/trade/trade_bloc.dart';

class OfferDetailScreen extends StatefulWidget {
  final String offerId;

  const OfferDetailScreen({super.key, required this.offerId});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context
        .read<MarketBloc>()
        .add(MarketOfferSelected(offerId: widget.offerId));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Color _trustColor(double rating) {
    if (rating >= 0.95) return AppColors.trustExcellent;
    if (rating >= 0.8) return AppColors.trustHigh;
    if (rating >= 0.6) return AppColors.trustAverage;
    if (rating >= 0.4) return AppColors.trustLow;
    if (rating >= 0.2) return AppColors.trustVeryLow;
    return AppColors.trustUnproven;
  }

  String _trustLabel(double rating) {
    if (rating >= 0.95) return 'Excellent';
    if (rating >= 0.8) return 'High';
    if (rating >= 0.6) return 'Average';
    if (rating >= 0.4) return 'Low';
    if (rating >= 0.2) return 'Very Low';
    return 'Unproven';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TradeBloc, TradeState>(
      listener: (context, tradeState) {
        if (tradeState.successMessage != null &&
            tradeState.currentTrade != null) {
          context.go('/trades/${tradeState.currentTrade!.id}/chat');
        }
        if (tradeState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tradeState.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, tradeState) {
        return BlocBuilder<MarketBloc, MarketState>(
          builder: (context, marketState) {
            final offer = marketState.selectedOffer;

            if (offer == null && marketState.isLoading) {
              return Scaffold(
                backgroundColor: AppColors.darkBackground,
                appBar: _buildAppBar(),
                body: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (offer == null) {
              return Scaffold(
                backgroundColor: AppColors.darkBackground,
                appBar: _buildAppBar(),
                body: Center(
                  child: Text(
                    'Offer not found',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            final isBuy = offer.tradeType == TradeType.buy;
            final accentColor =
                isBuy ? AppColors.buyAccent : AppColors.sellAccent;

            return Scaffold(
              backgroundColor: AppColors.darkBackground,
              appBar: _buildAppBar(),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTradeTypeHeader(offer, accentColor),
                      const SizedBox(height: 20),
                      _buildPriceSection(offer),
                      const SizedBox(height: 20),
                      _buildDetailsCard(offer),
                      const SizedBox(height: 20),
                      _buildSellerInfoCard(offer),
                      const SizedBox(height: 20),
                      _buildTermsSection(offer),
                      const SizedBox(height: 24),
                      _buildAmountInput(offer),
                      const SizedBox(height: 12),
                      _buildCalculatedFiat(offer),
                      const SizedBox(height: 24),
                      _buildStartTradeButton(
                          offer, accentColor, tradeState.isLoading),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Offer Details',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildTradeTypeHeader(Offer offer, Color accent) {
    final isBuy = offer.tradeType == TradeType.buy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isBuy ? 'Buy USDT' : 'Sell USDT',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Offer offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '${offer.pricePerUsdt.toStringAsFixed(2)} ${offer.fiatCurrency}',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'per USDT',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Margin: ${offer.marginPercent >= 0 ? '+' : ''}${offer.marginPercent.toStringAsFixed(2)}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _detailRow('Payment Method', offer.paymentMethod),
          const Divider(color: AppColors.border, height: 20),
          _detailRow('Fiat Currency', offer.fiatCurrency),
          const Divider(color: AppColors.border, height: 20),
          _detailRow(
            'Limits',
            '${offer.minAmount.toStringAsFixed(0)} – ${offer.maxAmount.toStringAsFixed(0)} ${offer.fiatCurrency}',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfoCard(Offer offer) {
    final trustColor = _trustColor(offer.traderRating);
    final trustLabel = _trustLabel(offer.traderRating);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trader Info',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withAlpha(40),
                child: Text(
                  offer.traderNickname.isNotEmpty
                      ? offer.traderNickname[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          offer.traderNickname,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: offer.traderOnline
                                ? AppColors.online
                                : AppColors.offline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          offer.traderOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: offer.traderOnline
                                ? AppColors.online
                                : AppColors.offline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.traderTradeCount} trades',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip(
                'Rating',
                '${(offer.traderRating * 100).toStringAsFixed(0)}%',
                trustColor,
              ),
              const SizedBox(width: 8),
              _statChip(
                'Trust',
                trustLabel,
                trustColor,
              ),
              const SizedBox(width: 8),
              _statChip(
                'Trades',
                '${offer.traderTradeCount}',
                AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(Offer offer) {
    if (offer.terms.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trade Terms',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.terms,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(Offer offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount (USDT)',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter an amount';
            final amount = double.tryParse(value);
            if (amount == null) return 'Invalid number';
            final fiatAmount = amount * offer.pricePerUsdt;
            if (fiatAmount < offer.minAmount) {
              return 'Minimum is ${offer.minAmount.toStringAsFixed(0)} ${offer.fiatCurrency}';
            }
            if (fiatAmount > offer.maxAmount) {
              return 'Maximum is ${offer.maxAmount.toStringAsFixed(0)} ${offer.fiatCurrency}';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            suffixText: 'USDT',
            suffixStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppColors.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Limits: ${offer.minAmount.toStringAsFixed(0)} – ${offer.maxAmount.toStringAsFixed(0)} ${offer.fiatCurrency}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatedFiat(Offer offer) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fiat = amount * offer.pricePerUsdt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You will pay',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${fiat.toStringAsFixed(2)} ${offer.fiatCurrency}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartTradeButton(Offer offer, Color accent, bool isLoading) {
    final isBuy = offer.tradeType == TradeType.buy;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: accent.withAlpha(80),
        ),
        onPressed: isLoading
            ? null
            : () {
                if (_formKey.currentState?.validate() ?? false) {
                  final amount = double.parse(_amountController.text);
                  context.read<TradeBloc>().add(
                        TradeInitiated(
                          offerId: offer.id,
                          amount: amount,
                        ),
                      );
                }
              },
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isBuy ? 'Buy USDT' : 'Sell USDT',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
