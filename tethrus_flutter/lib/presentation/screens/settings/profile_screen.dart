import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/trader_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  TraderProfile get _profile => TraderProfile(
        id: 'self',
        nickname: 'My Nickname',
        accountCreated: DateTime.now().subtract(const Duration(days: 120)),
        lastSeen: DateTime.now(),
        tradeCount: 47,
        completedTrades: 44,
        completionRate: 0.936,
        positiveRating: 0.95,
        trustLevel: TrustLevel.high,
        isOnline: true,
        recentFeedback: [
          TraderFeedback(
            id: '1',
            fromTrader: 'trader1',
            fromNickname: 'CryptoKing',
            isPositive: true,
            comment: 'Fast and reliable trader!',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          TraderFeedback(
            id: '2',
            fromTrader: 'trader2',
            fromNickname: 'BitMaster',
            isPositive: true,
            comment: 'Great experience, smooth trade.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          TraderFeedback(
            id: '3',
            fromTrader: 'trader3',
            fromNickname: 'SatoshiFan',
            isPositive: false,
            comment: 'Slow to respond.',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context, profile),
          const SizedBox(height: 20),
          _buildTradeStats(profile),
          const SizedBox(height: 20),
          _buildRatingAndTrust(profile),
          const SizedBox(height: 20),
          _buildFeedbackSection(profile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, TraderProfile profile) {
    final age = DateTime.now().difference(profile.accountCreated);
    final ageText = age.inDays > 30
        ? '${(age.inDays / 30).floor()} months'
        : '${age.inDays} days';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                profile.nickname.isNotEmpty
                    ? profile.nickname[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.nickname,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                onPressed: () => _showEditNicknameDialog(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Member for $ageText',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Nickname',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new nickname',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Save',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeStats(TraderProfile profile) {
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
            'Trade Statistics',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Total Trades', '${profile.tradeCount}',
                  AppColors.info),
              const SizedBox(width: 12),
              _statCard('Completed', '${profile.completedTrades}',
                  AppColors.buyAccent),
              const SizedBox(width: 12),
              _statCard(
                  'Rate',
                  '${(profile.completionRate * 100).toStringAsFixed(1)}%',
                  AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndTrust(TraderProfile profile) {
    final trustColor = _trustColor(profile.trustLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${(profile.positiveRating * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.buyAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Positive Rating',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: trustColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: trustColor.withAlpha(60)),
                  ),
                  child: Text(
                    profile.trustLevelLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: trustColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trust Level',
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
    );
  }

  Color _trustColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.excellent:
        return AppColors.trustExcellent;
      case TrustLevel.high:
        return AppColors.trustHigh;
      case TrustLevel.average:
        return AppColors.trustAverage;
      case TrustLevel.low:
        return AppColors.trustLow;
      case TrustLevel.veryLow:
        return AppColors.trustVeryLow;
      case TrustLevel.unproven:
        return AppColors.trustUnproven;
    }
  }

  Widget _buildFeedbackSection(TraderProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent Feedback',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (profile.recentFeedback.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'No feedback yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...profile.recentFeedback
              .map((fb) => _buildFeedbackCard(fb)),
      ],
    );
  }

  Widget _buildFeedbackCard(TraderFeedback fb) {
    final age = DateTime.now().difference(fb.createdAt);
    final ageText = age.inDays > 0 ? '${age.inDays}d ago' : 'Today';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            fb.isPositive ? Icons.thumb_up : Icons.thumb_down,
            size: 18,
            color: fb.isPositive ? AppColors.buyAccent : AppColors.sellAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fb.fromNickname,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ageText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (fb.comment != null && fb.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    fb.comment!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
