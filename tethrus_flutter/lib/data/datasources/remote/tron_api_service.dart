import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class TronApiService {
  final Dio _dio;

  TronApiService(this._dio);

  Future<double> getUsdtBalance(String address) async {
    try {
      final response = await _dio.post(
        '${AppConstants.tronGridApiUrl}/wallet/triggerconstantcontract',
        data: {
          'owner_address': address,
          'contract_address': AppConstants.usdtContractAddress,
          'function_selector': 'balanceOf(address)',
          'parameter': _padAddress(address),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final result = response.data['constant_result'];
        if (result != null && result.isNotEmpty) {
          final hex = result[0] as String;
          final balance = BigInt.parse(hex, radix: 16);
          return balance.toDouble() / 1e6;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getTrxBalance(String address) async {
    try {
      final response = await _dio.post(
        '${AppConstants.tronGridApiUrl}/wallet/getaccount',
        data: {'address': address, 'visible': true},
      );
      if (response.statusCode == 200 && response.data != null) {
        final balance = response.data['balance'] ?? 0;
        return balance / 1e6;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> createUsdtTransfer({
    required String fromAddress,
    required String toAddress,
    required double amount,
  }) async {
    final amountSun = (amount * 1e6).toInt();
    final response = await _dio.post(
      '${AppConstants.tronGridApiUrl}/wallet/triggersmartcontract',
      data: {
        'owner_address': fromAddress,
        'contract_address': AppConstants.usdtContractAddress,
        'function_selector': 'transfer(address,uint256)',
        'parameter': _padAddress(toAddress) + _padUint256(amountSun),
        'fee_limit': 100000000,
        'visible': true,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> broadcastTransaction(
      Map<String, dynamic> signedTx) async {
    final response = await _dio.post(
      '${AppConstants.tronGridApiUrl}/wallet/broadcasttransaction',
      data: signedTx,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory(
      String address) async {
    try {
      final response = await _dio.get(
        '${AppConstants.tronGridApiUrl}/v1/accounts/$address/transactions/trc20',
        queryParameters: {
          'limit': 50,
          'contract_address': AppConstants.usdtContractAddress,
        },
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<double> estimateFee() async {
    return 13.0; // Standard TRC20 transfer fee in TRX (energy + bandwidth)
  }

  String _padAddress(String address) {
    final hex = address.replaceFirst('T', '41');
    return hex.padLeft(64, '0');
  }

  String _padUint256(int value) {
    return value.toRadixString(16).padLeft(64, '0');
  }
}
