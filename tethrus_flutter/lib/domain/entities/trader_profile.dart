import 'package:equatable/equatable.dart';

enum TrustLevel {
  unproven,
  veryLow,
  low,
  average,
  high,
  excellent,
}

class TraderProfile extends Equatable {
  final String id;
  final String nickname;
  final DateTime accountCreated;
  final DateTime lastSeen;
  final int tradeCount;
  final int completedTrades;
  final double completionRate;
  final double positiveRating;
  final TrustLevel trustLevel;
  final bool isOnline;
  final List<TraderFeedback> recentFeedback;

  const TraderProfile({
    required this.id,
    required this.nickname,
    required this.accountCreated,
    required this.lastSeen,
    required this.tradeCount,
    required this.completedTrades,
    required this.completionRate,
    required this.positiveRating,
    required this.trustLevel,
    required this.isOnline,
    this.recentFeedback = const [],
  });

  String get trustLevelLabel {
    switch (trustLevel) {
      case TrustLevel.unproven:
        return 'Unproven';
      case TrustLevel.veryLow:
        return 'Very Low';
      case TrustLevel.low:
        return 'Low';
      case TrustLevel.average:
        return 'Average';
      case TrustLevel.high:
        return 'High';
      case TrustLevel.excellent:
        return 'Excellent';
    }
  }

  @override
  List<Object?> get props => [id, tradeCount, positiveRating, trustLevel];
}

class TraderFeedback extends Equatable {
  final String id;
  final String fromTrader;
  final String fromNickname;
  final bool isPositive;
  final String? comment;
  final DateTime createdAt;

  const TraderFeedback({
    required this.id,
    required this.fromTrader,
    required this.fromNickname,
    required this.isPositive,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
