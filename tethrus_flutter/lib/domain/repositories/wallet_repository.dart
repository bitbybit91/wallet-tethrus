import '../entities/wallet_account.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<WalletAccount> createWallet();
  Future<WalletAccount> importFromMnemonic(List<String> mnemonic);
  Future<WalletAccount> importFromPrivateKey(String privateKey);
  Future<WalletAccount?> addWatchOnlyAccount(String address);
  Future<List<WalletAccount>> getAccounts();
  Future<WalletAccount?> getDefaultAccount();
  Future<void> setDefaultAccount(String accountId);
  Future<double> getUsdtBalance(String address);
  Future<double> getTrxBalance(String address);
  Future<void> refreshBalances(String address);
  Future<String> sendUsdt({
    required String fromAddress,
    required String toAddress,
    required double amount,
  });
  Future<double> estimateFee();
  Future<List<WalletTransaction>> getTransactionHistory(String address);
  Future<List<String>> getMnemonic();
  Future<bool> hasMnemonic();
  Future<String> getReceiveAddress();
}
