import 'package:equatable/equatable.dart';

class WalletAccount extends Equatable {
  final String id;
  final String address;
  final String? nickname;
  final WalletAccountType type;
  final double usdtBalance;
  final double trxBalance;
  final bool isDefault;
  final DateTime createdAt;

  const WalletAccount({
    required this.id,
    required this.address,
    this.nickname,
    required this.type,
    this.usdtBalance = 0.0,
    this.trxBalance = 0.0,
    this.isDefault = false,
    required this.createdAt,
  });

  WalletAccount copyWith({
    double? usdtBalance,
    double? trxBalance,
    String? nickname,
    bool? isDefault,
  }) {
    return WalletAccount(
      id: id,
      address: address,
      nickname: nickname ?? this.nickname,
      type: type,
      usdtBalance: usdtBalance ?? this.usdtBalance,
      trxBalance: trxBalance ?? this.trxBalance,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, address, usdtBalance, trxBalance];
}

enum WalletAccountType {
  standard,
  watchOnly,
  singleAddress,
  hardware,
}
