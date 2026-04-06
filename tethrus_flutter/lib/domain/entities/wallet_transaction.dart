import 'package:equatable/equatable.dart';

enum TransactionStatus { pending, confirmed, failed }

enum TransactionType { send, receive }

class WalletTransaction extends Equatable {
  final String id;
  final String txHash;
  final TransactionType type;
  final double amount;
  final String tokenSymbol;
  final String fromAddress;
  final String toAddress;
  final TransactionStatus status;
  final DateTime timestamp;
  final double fee;
  final int? blockNumber;
  final int confirmations;

  const WalletTransaction({
    required this.id,
    required this.txHash,
    required this.type,
    required this.amount,
    required this.tokenSymbol,
    required this.fromAddress,
    required this.toAddress,
    required this.status,
    required this.timestamp,
    required this.fee,
    this.blockNumber,
    this.confirmations = 0,
  });

  @override
  List<Object?> get props => [id, txHash, status];
}
