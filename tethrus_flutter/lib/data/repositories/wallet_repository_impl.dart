import '../../domain/entities/wallet_account.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/remote/tron_api_service.dart';
import '../datasources/local/secure_storage_service.dart';
import '../../core/crypto/wallet_crypto.dart';

class WalletRepositoryImpl implements WalletRepository {
  final TronApiService tronApi;
  final SecureStorageService secureStorage;
  final WalletCrypto walletCrypto;

  final List<WalletAccount> _accounts = [];
  String? _currentAddress;

  WalletRepositoryImpl({
    required this.tronApi,
    required this.secureStorage,
    required this.walletCrypto,
  });

  @override
  Future<WalletAccount> createWallet() async {
    final mnemonic = walletCrypto.generateMnemonic();
    await secureStorage.saveMnemonic(mnemonic.join(' '));

    final seed = walletCrypto.mnemonicToSeed(mnemonic);
    final privateKey = walletCrypto.derivePrivateKey(seed);
    await secureStorage.savePrivateKey(privateKey);

    final address = walletCrypto.privateKeyToAddress(privateKey);
    _currentAddress = address;

    final account = WalletAccount(
      id: 'account_0',
      address: address,
      nickname: 'Main Account',
      type: WalletAccountType.standard,
      isDefault: true,
      createdAt: DateTime.now(),
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<WalletAccount> importFromMnemonic(List<String> mnemonic) async {
    if (!walletCrypto.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }

    await secureStorage.saveMnemonic(mnemonic.join(' '));
    final seed = walletCrypto.mnemonicToSeed(mnemonic);
    final privateKey = walletCrypto.derivePrivateKey(seed);
    await secureStorage.savePrivateKey(privateKey);

    final address = walletCrypto.privateKeyToAddress(privateKey);
    _currentAddress = address;

    final account = WalletAccount(
      id: 'account_${_accounts.length}',
      address: address,
      nickname: 'Imported Account',
      type: WalletAccountType.standard,
      isDefault: _accounts.isEmpty,
      createdAt: DateTime.now(),
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<WalletAccount> importFromPrivateKey(String privateKey) async {
    await secureStorage.savePrivateKey(privateKey);
    final address = walletCrypto.privateKeyToAddress(privateKey);
    _currentAddress = address;

    final account = WalletAccount(
      id: 'account_${_accounts.length}',
      address: address,
      nickname: 'Imported (Key)',
      type: WalletAccountType.singleAddress,
      isDefault: _accounts.isEmpty,
      createdAt: DateTime.now(),
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<WalletAccount?> addWatchOnlyAccount(String address) async {
    final account = WalletAccount(
      id: 'account_${_accounts.length}',
      address: address,
      nickname: 'Watch Only',
      type: WalletAccountType.watchOnly,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<List<WalletAccount>> getAccounts() async {
    return List.unmodifiable(_accounts);
  }

  @override
  Future<WalletAccount?> getDefaultAccount() async {
    if (_accounts.isEmpty) return null;
    return _accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => _accounts.first,
    );
  }

  @override
  Future<void> setDefaultAccount(String accountId) async {
    for (int i = 0; i < _accounts.length; i++) {
      _accounts[i] = _accounts[i].copyWith(
        isDefault: _accounts[i].id == accountId,
      );
    }
  }

  @override
  Future<double> getUsdtBalance(String address) async {
    return await tronApi.getUsdtBalance(address);
  }

  @override
  Future<double> getTrxBalance(String address) async {
    return await tronApi.getTrxBalance(address);
  }

  @override
  Future<void> refreshBalances(String address) async {
    final usdtBalance = await tronApi.getUsdtBalance(address);
    final trxBalance = await tronApi.getTrxBalance(address);

    final index = _accounts.indexWhere((a) => a.address == address);
    if (index >= 0) {
      _accounts[index] = _accounts[index].copyWith(
        usdtBalance: usdtBalance,
        trxBalance: trxBalance,
      );
    }
  }

  @override
  Future<String> sendUsdt({
    required String fromAddress,
    required String toAddress,
    required double amount,
  }) async {
    final txData = await tronApi.createUsdtTransfer(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
    );

    // In production, sign the transaction with private key locally
    // For now, return the transaction hash
    final result = await tronApi.broadcastTransaction(txData);
    return result['txid'] ?? 'pending';
  }

  @override
  Future<double> estimateFee() async {
    return await tronApi.estimateFee();
  }

  @override
  Future<List<WalletTransaction>> getTransactionHistory(String address) async {
    final txList = await tronApi.getTransactionHistory(address);
    return txList.map((tx) {
      final value = double.tryParse(tx['value'] ?? '0') ?? 0;
      return WalletTransaction(
        id: tx['transaction_id'] ?? '',
        txHash: tx['transaction_id'] ?? '',
        type: tx['from'] == address
            ? TransactionType.send
            : TransactionType.receive,
        amount: value / 1e6,
        tokenSymbol: 'USDT',
        fromAddress: tx['from'] ?? '',
        toAddress: tx['to'] ?? '',
        status: TransactionStatus.confirmed,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (tx['block_timestamp'] ?? 0) as int,
        ),
        fee: 0,
        confirmations: 100,
      );
    }).toList();
  }

  @override
  Future<List<String>> getMnemonic() async {
    final mnemonic = await secureStorage.getMnemonic();
    if (mnemonic == null) throw Exception('No mnemonic stored');
    return mnemonic.split(' ');
  }

  @override
  Future<bool> hasMnemonic() async {
    final mnemonic = await secureStorage.getMnemonic();
    return mnemonic != null && mnemonic.isNotEmpty;
  }

  @override
  Future<String> getReceiveAddress() async {
    if (_currentAddress != null) return _currentAddress!;
    final account = await getDefaultAccount();
    if (account != null) return account.address;
    throw Exception('No wallet account found');
  }
}
