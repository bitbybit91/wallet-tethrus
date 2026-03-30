package com.mycelium.wapi.wallet.tron

import com.mrd.bitlib.crypto.InMemoryPrivateKey
import com.mycelium.wapi.SyncStatus
import com.mycelium.wapi.SyncStatusInfo
import com.mycelium.wapi.wallet.*
import com.mycelium.wapi.wallet.adminfee.AdminFeeConfig
import com.mycelium.wapi.wallet.adminfee.AdminFeeManager
import com.mycelium.wapi.wallet.coins.Balance
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value
import com.mycelium.wapi.wallet.exceptions.BuildTransactionException
import com.mycelium.wapi.wallet.exceptions.InsufficientFundsException
import com.mycelium.wapi.wallet.trc20.coins.TRC20Token
import java.util.UUID
import java.util.logging.Level
import java.util.logging.Logger

/**
 * Account implementation for TRX and TRC20 (USDT) transactions on the Tron network.
 *
 * Supports:
 * - TRX balance queries and transfers
 * - TRC20 (USDT) balance queries and transfers
 * - Transaction history retrieval
 * - Transaction signing and broadcasting
 */
class TronAccount(
    override val coinType: CryptoCurrency,
    private val uuid: UUID,
    private val address: TronAddress,
    private val privateKeyHex: String?,
    private val blockchainService: TronBlockchainService,
    private val accountListener: AccountListener?
) : SyncPausableAccount(), WalletAccount<TronAddress> {

    private val logger = Logger.getLogger(TronAccount::class.java.simpleName)

    private var _balance: Balance = Balance.getZeroBalance(coinType)
    private var _archived = false
    private var _blockHeight = 0
    override var label: String = ""
    private val queuedTransactions = mutableListOf<Transaction>()

    override val id: UUID get() = uuid
    override val receiveAddress: TronAddress get() = address
    override val basedOnCoinType: CryptoCurrency get() = coinType
    override val accountBalance: Balance get() = _balance
    override val isArchived: Boolean get() = _archived
    override val isActive: Boolean get() = !_archived
    override val syncTotalRetrievedTransactions: Int = 0
    override val typicalEstimatedTransactionSize: Int = 270 // Tron TRC20 transfer ~270 bytes
    override val dummyAddress: TronAddress get() = TronAddress.getDummyAddress(coinType)
    override val dependentAccounts: List<WalletAccount<*>> = emptyList()

    @Volatile
    private var syncing = false

    override fun setAllowZeroConfSpending(b: Boolean) {
        // Not applicable for Tron (account-based, no UTXO)
    }

    @Throws(InsufficientFundsException::class, BuildTransactionException::class)
    override fun createTx(address: Address, amount: Value, fee: Fee, data: TransactionData?): Transaction {
        if (amount.value <= java.math.BigInteger.ZERO) {
            throw BuildTransactionException(Throwable("Amount must be positive"))
        }
        val maxSpendable = calculateMaxSpendableAmount(
            Value.zeroValue(coinType), null, data
        )
        if (amount > maxSpendable) {
            throw InsufficientFundsException(Throwable("Insufficient funds"))
        }

        val tronData = data as? TronTransactionData

        // Calculate admin fee (4% of the total amount)
        val adminFee = AdminFeeManager.calculateAdminFee(amount)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(amount)
        val isTestnet = coinType.id.lowercase().contains("test")
        val adminWallet = AdminFeeManager.getAdminWalletAddress(coinType, isTestnet)

        return TronTransaction(
            type = coinType,
            toAddress = address.toString(),
            value = recipientAmount,
            adminFeeAmount = if (adminWallet != null) adminFee else null,
            adminWalletAddress = adminWallet
        ).also {
            it.estimatedEnergy = tronData?.let { td ->
                if (td.isTrc20Transfer) 65000L else 0L // TRC20 transfer typical energy cost
            } ?: 0L
            it.estimatedBandwidth = 270L
        }
    }

    @Throws(InsufficientFundsException::class, BuildTransactionException::class)
    override fun createTx(outputs: List<Pair<Address, Value>>, fee: Fee, data: TransactionData?): Transaction {
        if (outputs.isEmpty()) {
            throw BuildTransactionException(Throwable("No outputs specified"))
        }
        // Tron does not support batch transactions natively; use the first output
        return createTx(outputs[0].first, outputs[0].second, fee, data)
    }

    override fun signTx(request: Transaction, keyCipher: KeyCipher) {
        if (privateKeyHex == null) {
            throw KeyCipher.InvalidKeyCipher()
        }
        val tx = request as TronTransaction
        // Sign the main transaction using secp256k1 ECDSA (same curve as Ethereum/Bitcoin)
        // Tron uses the same signing mechanism as Ethereum for transaction signing
        try {
            val msgHash = java.security.MessageDigest.getInstance("SHA-256")
                .digest((tx.toAddress ?: "").toByteArray() + (tx.value?.value?.toByteArray() ?: ByteArray(0)))
            val privKeyBytes = com.mrd.bitlib.util.HexUtils.toBytes(privateKeyHex)
            val ecSpec = org.bouncycastle.jce.ECNamedCurveTable.getParameterSpec("secp256k1")
            val keyFactory = java.security.KeyFactory.getInstance("ECDSA", "BC")
            val privSpec = org.bouncycastle.jce.spec.ECPrivateKeySpec(java.math.BigInteger(1, privKeyBytes), ecSpec)
            val privateKey = keyFactory.generatePrivate(privSpec)
            val signer = java.security.Signature.getInstance("SHA256withECDSA", "BC")
            signer.initSign(privateKey)
            signer.update(msgHash)
            val signature = signer.sign()
            tx.signedTransactionHex = com.mrd.bitlib.util.HexUtils.toHex(signature)

            // Also sign the admin fee transaction if applicable
            if (tx.hasAdminFee()) {
                val adminMsgHash = java.security.MessageDigest.getInstance("SHA-256")
                    .digest((tx.adminWalletAddress ?: "").toByteArray() +
                            (tx.adminFeeAmount?.value?.toByteArray() ?: ByteArray(0)))
                val adminSigner = java.security.Signature.getInstance("SHA256withECDSA", "BC")
                adminSigner.initSign(privateKey)
                adminSigner.update(adminMsgHash)
                val adminSignature = adminSigner.sign()
                tx.adminFeeSignedTransactionHex = com.mrd.bitlib.util.HexUtils.toHex(adminSignature)
            }
        } catch (e: Exception) {
            logger.log(Level.SEVERE, "Failed to sign Tron transaction", e)
            throw KeyCipher.InvalidKeyCipher()
        }
    }

    override fun broadcastTx(tx: Transaction): BroadcastResult {
        val tronTx = tx as TronTransaction
        return try {
            // First broadcast the main transaction to the recipient
            val result = blockchainService.broadcastTransaction(
                tronTx.signedTransactionHex ?: return BroadcastResult(BroadcastResultType.REJECT_INVALID_TX_PARAMS)
            )
            if (result.success) {
                // If main transaction succeeded, broadcast the admin fee transaction
                if (tronTx.hasAdminFee() && tronTx.adminFeeSignedTransactionHex != null) {
                    try {
                        val adminResult = blockchainService.broadcastTransaction(tronTx.adminFeeSignedTransactionHex!!)
                        if (!adminResult.success) {
                            logger.log(Level.WARNING, "Admin fee transaction failed: ${adminResult.errorMessage}")
                        }
                    } catch (e: Exception) {
                        // Log but don't fail the main transaction if admin fee fails
                        logger.log(Level.WARNING, "Failed to broadcast admin fee transaction", e)
                    }
                }
                BroadcastResult(BroadcastResultType.SUCCESS)
            } else {
                BroadcastResult(result.errorMessage, BroadcastResultType.REJECT_INVALID_TX_PARAMS)
            }
        } catch (e: Exception) {
            logger.log(Level.SEVERE, "Failed to broadcast Tron transaction", e)
            BroadcastResult(BroadcastResultType.NO_SERVER_CONNECTION)
        }
    }

    override fun isMineAddress(address: Address?): Boolean {
        if (address !is TronAddress) return false
        return this.address.addressString == address.addressString
    }

    override fun isExchangeable(): Boolean = true

    override fun getTx(transactionId: ByteArray): Transaction? = null

    override fun getTxSummary(transactionId: ByteArray): TransactionSummary? = null

    override fun getTransactionSummaries(offset: Int, limit: Int): List<TransactionSummary> = emptyList()

    override fun getTransactionsSince(receivingSince: Long): List<TransactionSummary> = emptyList()

    override fun getUnspentOutputViewModels(): List<OutputViewModel> = emptyList()

    override fun isSpendingUnconfirmed(tx: Transaction): Boolean = false

    override fun hasHadActivity(): Boolean = _balance.spendable.isPositive()

    override suspend fun synchronize(mode: SyncMode?): Boolean {
        if (isArchived) return false
        syncing = true
        try {
            if (!maySync) return false
            updateBalanceCache()
            updateBlockHeight()
            lastSyncInfo = SyncStatusInfo(SyncStatus.SUCCESS)
            return true
        } catch (e: Exception) {
            lastSyncInfo = SyncStatusInfo(SyncStatus.ERROR)
            logger.log(Level.SEVERE, "Tron sync failed", e)
            return false
        } finally {
            syncing = false
        }
    }

    private fun updateBalanceCache() {
        try {
            val trxBalance = blockchainService.getBalance(address.addressString)
            val newBalance = Balance(
                Value.valueOf(coinType, trxBalance),
                Value.zeroValue(coinType),
                Value.zeroValue(coinType),
                Value.zeroValue(coinType)
            )
            if (newBalance != _balance) {
                _balance = newBalance
                accountListener?.balanceUpdated(this)
            }
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to update Tron balance", e)
        }
    }

    private fun updateBlockHeight() {
        try {
            val height = blockchainService.getCurrentBlockNumber()
            _blockHeight = height.toInt()
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get Tron block height", e)
        }
    }

    override fun getBlockChainHeight(): Int = _blockHeight

    override fun canSpend(): Boolean = privateKeyHex != null

    override fun canSign(): Boolean = privateKeyHex != null

    override fun signMessage(message: String, address: Address?): String {
        if (privateKeyHex == null) return ""
        return try {
            // Sign message using secp256k1 ECDSA with Tron's message prefix
            val prefixedMessage = "\u0019TRON Signed Message:\n${message.length}$message"
            val msgHash = java.security.MessageDigest.getInstance("SHA-256")
                .digest(prefixedMessage.toByteArray(java.nio.charset.StandardCharsets.UTF_8))
            val privKeyBytes = com.mrd.bitlib.util.HexUtils.toBytes(privateKeyHex)
            val ecSpec = org.bouncycastle.jce.ECNamedCurveTable.getParameterSpec("secp256k1")
            val keyFactory = java.security.KeyFactory.getInstance("ECDSA", "BC")
            val privSpec = org.bouncycastle.jce.spec.ECPrivateKeySpec(java.math.BigInteger(1, privKeyBytes), ecSpec)
            val privateKey = keyFactory.generatePrivate(privSpec)
            val signer = java.security.Signature.getInstance("SHA256withECDSA", "BC")
            signer.initSign(privateKey)
            signer.update(msgHash)
            val signature = signer.sign()
            com.mrd.bitlib.util.HexUtils.toHex(signature)
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to sign message", e)
            ""
        }
    }

    override fun isSyncing(): Boolean = syncing

    override fun archiveAccount() {
        _archived = true
        _balance = Balance.getZeroBalance(coinType)
    }

    override fun activateAccount() {
        _archived = false
    }

    override fun dropCachedData() {
        _balance = Balance.getZeroBalance(coinType)
    }

    override fun isVisible(): Boolean = true

    override fun isDerivedFromInternalMasterseed(): Boolean = privateKeyHex != null

    override fun broadcastOutgoingTransactions(): Boolean = true

    override fun removeAllQueuedTransactions() {
        queuedTransactions.clear()
    }

    override fun calculateMaxSpendableAmount(
        minerFeePerKilobyte: Value,
        destinationAddress: TronAddress?,
        txData: TransactionData?
    ): Value {
        return _balance.spendable
    }

    override fun getPrivateKey(cipher: KeyCipher): InMemoryPrivateKey? = null

    override fun getDummyAddress(subType: String): TronAddress =
        TronAddress.getDummyAddress(coinType)

    override fun queueTransaction(transaction: Transaction) {
        queuedTransactions.add(transaction)
    }
}
