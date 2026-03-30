package com.mycelium.wapi.wallet.tron

/**
 * Service interface for interacting with the Tron blockchain via TronGrid API.
 *
 * TronGrid provides a full suite of APIs compatible with the Tron Full Node API
 * for querying account information, broadcasting transactions, and interacting
 * with TRC20 smart contracts like USDT.
 *
 * Mainnet: https://api.trongrid.io
 * Nile Testnet: https://nile.trongrid.io
 * Shasta Testnet: https://api.shasta.trongrid.io
 */
interface TronBlockchainService {

    /**
     * Get the TRX balance for an address in SUN (1 TRX = 1,000,000 SUN).
     */
    fun getBalance(address: String): Long

    /**
     * Get the TRC20 token balance for an address.
     * @param address The Tron address
     * @param contractAddress The TRC20 contract address (e.g., USDT: TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t)
     * @return Token balance in the token's smallest unit
     */
    fun getTrc20Balance(address: String, contractAddress: String): Long

    /**
     * Get transaction history for an address.
     */
    fun getTransactions(address: String, limit: Int = 50, fingerprint: String? = null): List<TronTransactionInfo>

    /**
     * Get TRC20 token transfer history for an address.
     */
    fun getTrc20Transfers(
        address: String,
        contractAddress: String,
        limit: Int = 50,
        fingerprint: String? = null
    ): List<TronTrc20TransferInfo>

    /**
     * Broadcast a signed transaction to the Tron network.
     */
    fun broadcastTransaction(signedTransaction: String): TronBroadcastResult

    /**
     * Get the current block number.
     */
    fun getCurrentBlockNumber(): Long

    /**
     * Get account resource information (bandwidth, energy).
     */
    fun getAccountResources(address: String): TronAccountResources

    /**
     * Estimate the energy cost for a TRC20 transfer.
     */
    fun estimateEnergy(
        ownerAddress: String,
        contractAddress: String,
        functionSelector: String,
        parameter: String
    ): Long
}

data class TronTransactionInfo(
    val txId: String,
    val blockNumber: Long,
    val timestamp: Long,
    val from: String,
    val to: String,
    val amount: Long,
    val confirmed: Boolean
)

data class TronTrc20TransferInfo(
    val txId: String,
    val blockNumber: Long,
    val timestamp: Long,
    val from: String,
    val to: String,
    val amount: Long,
    val contractAddress: String,
    val tokenSymbol: String,
    val tokenDecimals: Int,
    val confirmed: Boolean
)

data class TronBroadcastResult(
    val success: Boolean,
    val txId: String?,
    val errorMessage: String?
)

data class TronAccountResources(
    val bandwidth: Long,
    val energy: Long,
    val trxBalance: Long
)
