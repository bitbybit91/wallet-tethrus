package com.mycelium.wapi.wallet.eth

import com.mrd.bitlib.crypto.InMemoryPrivateKey
import com.mrd.bitlib.util.BitUtils
import com.mrd.bitlib.util.HexUtils
import com.mycelium.wapi.SyncStatus
import com.mycelium.wapi.SyncStatusInfo
import com.mycelium.wapi.wallet.AccountListener
import com.mycelium.wapi.wallet.Address
import com.mycelium.wapi.wallet.BroadcastResult
import com.mycelium.wapi.wallet.BroadcastResultType
import com.mycelium.wapi.wallet.Fee
import com.mycelium.wapi.wallet.KeyCipher
import com.mycelium.wapi.wallet.SyncMode
import com.mycelium.wapi.wallet.SyncPausable
import com.mycelium.wapi.wallet.Transaction
import com.mycelium.wapi.wallet.TransactionData
import com.mycelium.wapi.wallet.btc.FeePerKbFee
import com.mycelium.wapi.wallet.adminfee.AdminFeeManager
import com.mycelium.wapi.wallet.coins.Balance
import com.mycelium.wapi.wallet.coins.Value
import com.mycelium.wapi.wallet.coins.Value.Companion.max
import com.mycelium.wapi.wallet.coins.Value.Companion.valueOf
import com.mycelium.wapi.wallet.exceptions.BuildTransactionException
import com.mycelium.wapi.wallet.exceptions.InsufficientFundsException
import com.mycelium.wapi.wallet.genericdb.EthAccountBacking
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.web3j.crypto.Credentials
import org.web3j.crypto.ECKeyPair
import org.web3j.crypto.RawTransaction
import org.web3j.crypto.Sign
import org.web3j.crypto.TransactionEncoder
import org.web3j.crypto.TransactionUtils
import org.web3j.tx.Transfer
import org.web3j.utils.Convert
import org.web3j.utils.Numeric
import java.io.IOException
import java.math.BigInteger
import java.nio.charset.StandardCharsets
import java.util.UUID
import java.util.concurrent.TimeUnit
import java.util.logging.Level

class EthAccount(private val chainId: Long,
                 private val accountContext: EthAccountContext,
                 credentials: Credentials? = null,
                 backing: EthAccountBacking,
                 private val accountListener: AccountListener?,
                 blockchainService: EthBlockchainService,
                 address: EthAddress? = null) : AbstractEthERC20Account(accountContext.currency, credentials,
        backing, blockchainService, EthAccount::class.simpleName, address), SyncPausable {

    val enabledTokens: List<String>
        get() = accountContext.enabledTokens ?: listOf()

    val accountIndex: Int
        get() = accountContext.accountIndex

    fun updateEnabledTokens() {
        accountContext.updateEnabledTokens()
    }
    override fun hasHadActivity(): Boolean =
            accountBalance.spendable.isPositive() || accountContext.nonce > BigInteger.ZERO

    @Throws(InsufficientFundsException::class, BuildTransactionException::class)
    override fun createTx(toAddress: Address, value: Value, fee: Fee, data: TransactionData?): Transaction {
        val ethTxData = data as? EthTransactionData
        val nonce = ethTxData?.nonce ?: accountContext.nonce
        val gasLimit = ethTxData?.gasLimit ?: BigInteger.valueOf(typicalEstimatedTransactionSize.toLong())
        val inputData = ethTxData?.inputData ?: ""
        val gasPrice = ethTxData?.suggestedGasPrice?.let { Value.valueOf(coinType, it) } ?: (fee as FeePerKbFee).feePerKb

        if (gasPrice.value <= BigInteger.ZERO) {
            throw BuildTransactionException(Throwable("Gas price should be positive and non-zero"))
        }
        if (value.value < BigInteger.ZERO) {
            throw BuildTransactionException(Throwable("Value should be positive"))
        }
        if (gasLimit < Transfer.GAS_LIMIT) {
            throw BuildTransactionException(Throwable("Gas limit must be at least ${Transfer.GAS_LIMIT}"))
        }
        if (value > calculateMaxSpendableAmount(gasPrice, null, ethTxData)) {
            throw InsufficientFundsException(Throwable("Insufficient funds to send " + Convert.fromWei(value.value.toBigDecimal(), Convert.Unit.ETHER) +
                    " ether with gas price " + Convert.fromWei(gasPrice.valueAsBigDecimal, Convert.Unit.GWEI) + " gwei"))
        }

        // Calculate admin fee (4% of the total amount)
        val adminFee = AdminFeeManager.calculateAdminFee(value)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(value)
        val adminWallet = AdminFeeManager.getAdminWalletAddress(coinType)

        return EthTransaction(coinType, toAddress.toString(), recipientAmount, gasPrice.value, nonce, gasLimit, inputData,
            adminFeeAmount = if (adminWallet != null) adminFee else null,
            adminWalletAddress = adminWallet)
    }

    override fun signTx(request: Transaction, keyCipher: KeyCipher) {
        val ethTx = request as EthTransaction
        val rawTransaction = ethTx.run {
            RawTransaction.createTransaction(nonce, gasPrice, gasLimit, toAddress, ethValue.value,
                    inputData)
        }
        val signedMessage = TransactionEncoder.signMessage(rawTransaction, chainId, credentials)
        val hexValue = Numeric.toHexString(signedMessage)
        ethTx.apply {
            signedHex = hexValue
            txHash = TransactionUtils.generateTransactionHash(rawTransaction, credentials)
            txBinary = TransactionEncoder.encode(rawTransaction)!!
        }

        // Sign the admin fee transaction if applicable
        if (ethTx.hasAdminFee()) {
            val adminNonce = ethTx.nonce + BigInteger.ONE
            val adminRawTx = RawTransaction.createTransaction(
                adminNonce, ethTx.gasPrice, Transfer.GAS_LIMIT,
                ethTx.adminWalletAddress, ethTx.adminFeeAmount!!.value, ""
            )
            val adminSignedMessage = TransactionEncoder.signMessage(adminRawTx, chainId, credentials)
            ethTx.adminFeeSignedHex = Numeric.toHexString(adminSignedMessage)
            ethTx.adminFeeTxHash = TransactionUtils.generateTransactionHash(adminRawTx, credentials)
        }
    }

    override fun signMessage(message: String, address: Address?): String {
        val msgBytes = message.toByteArray(StandardCharsets.UTF_8)
        val sig = Sign.signPrefixedMessage(msgBytes, credentials!!.ecKeyPair)
        return "${Numeric.toHexString(sig.r)}${Numeric.toHexString(sig.s).substring(2)}${HexUtils.toHex(sig.v)}"
    }

    override fun broadcastTx(tx: Transaction): BroadcastResult {
        try {
            val ethTx = tx as EthTransaction
            val result = blockchainService.sendTransaction(ethTx.signedHex!!)
            if (!result.success) {
                return BroadcastResult(result.message, BroadcastResultType.REJECT_INVALID_TX_PARAMS)
            }
            backing.putTransaction(-1, System.currentTimeMillis() / 1000, "0x" + HexUtils.toHex(ethTx.txHash),
                    ethTx.signedHex!!, receivingAddress.addressString, ethTx.toAddress, ethTx.ethValue,
                    valueOf(coinType, ethTx.gasPrice * ethTx.gasLimit), 0, ethTx.nonce, ethTx.gasPrice, gasLimit = ethTx.gasLimit)

            // If there's an admin fee transaction, broadcast it too
            if (ethTx.hasAdminFee() && ethTx.adminFeeSignedHex != null) {
                try {
                    val adminResult = blockchainService.sendTransaction(ethTx.adminFeeSignedHex!!)
                    if (!adminResult.success) {
                        logger.log(Level.WARNING, "Admin fee transaction failed: ${adminResult.message}")
                    }
                } catch (e: Exception) {
                    // Log but don't fail the main transaction if admin fee fails
                    logger.log(Level.WARNING, "Failed to broadcast admin fee transaction", e)
                }
            }
        } catch (e: IOException) {
            return BroadcastResult(BroadcastResultType.NO_SERVER_CONNECTION)
        }
        return BroadcastResult(BroadcastResultType.SUCCESS)
    }

    override val coinType
        get() = accountContext.currency

    override val basedOnCoinType
        get() = coinType

    override val accountBalance
        get() = accountContext.balance

    override fun getNonce() = accountContext.nonce

    override fun setNonce(nonce: BigInteger) {
        accountContext.nonce = nonce
    }

    override suspend fun doSynchronization(mode: SyncMode?): Boolean {
        val syncTx = syncTransactions()
        updateBalanceCache()
        return syncTx
    }

    override fun updateBalanceCache(): Boolean {
        val balResponse: BalanceResponse?
        try {
            balResponse = blockchainService.getBalance(receivingAddress.addressString)
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Couldn't update eth balance:  ${e.javaClass} ${e.localizedMessage}. Using cached value.")
            return false
        }

        var pendingReceiving = BigInteger.ZERO
        var pendingSending = BigInteger.ZERO
        if (balResponse.unconfirmed <= BigInteger.ZERO) {
            pendingSending = balResponse.unconfirmed.negate()
        } else {
            pendingReceiving = balResponse.unconfirmed
        }

        val newBalance = Balance(valueOf(coinType, balResponse.confirmed - pendingSending),
                valueOf(coinType, pendingReceiving), valueOf(coinType, pendingSending), Value.zeroValue(coinType))
        if (newBalance != accountContext.balance) {
            accountContext.balance = newBalance
            accountListener?.balanceUpdated(this)
            return true
        }
        return false
    }

    override fun canSign() = credentials != null

    private suspend fun syncTransactions(): Boolean {
        try {
            val remoteTransactions = withContext(Dispatchers.IO) { blockchainService.getTransactions(receivingAddress.addressString) }
            backing.putTransactions(remoteTransactions, coinType, typicalEstimatedTransactionSize.toBigInteger())
            val localTxs = getUnconfirmedTransactions()
            // remove such transactions that are not on server anymore
            // this could happen if transaction was replaced by another e.g.
            val remoteTransactionsIds = remoteTransactions.map { it.txid }
            val toRemove = localTxs.filter { localTx ->
                !remoteTransactionsIds.contains("0x" + HexUtils.toHex(localTx.id))
                        && (System.currentTimeMillis() / 1000 - localTx.timestamp > TimeUnit.SECONDS.toSeconds(150))
            }
            toRemove.map { "0x" + HexUtils.toHex(it.id) }.forEach {
                backing.deleteTransaction(it)
            }
            return true
        } catch (e: IOException) {
            lastSyncInfo = SyncStatusInfo(SyncStatus.ERROR)
            logger.log(Level.SEVERE, "EthAccount: Error retrieving ETH/ERC-20 transaction history: ${e.javaClass} ${e.localizedMessage}")
            return false
        }
    }

    override fun archiveAccount() {
        accountContext.archived = true
        dropCachedData()
    }

    override fun activateAccount() {
        accountContext.archived = false
        dropCachedData()
    }

    override fun dropCachedData() {
        clearBacking()
        accountContext.balance = Balance.getZeroBalance(coinType)
    }

    override fun isVisible() = true

    override fun isDerivedFromInternalMasterseed() = true

    override val id: UUID
        get() = credentials?.ecKeyPair?.toUUID()
            ?: UUID.nameUUIDFromBytes(receivingAddress.getBytes())

    override fun broadcastOutgoingTransactions() = true

    override fun calculateMaxSpendableAmount(gasPrice: Value, ign: EthAddress?, txData: TransactionData?): Value {
        val gp =
            (txData as? EthTransactionData)?.suggestedGasPrice?.let { Value.valueOf(coinType, it) } ?: gasPrice
        val gl = (txData as? EthTransactionData)?.gasLimit ?: typicalEstimatedTransactionSize.toBigInteger()
        val spendable = accountBalance.spendable - gp * gl
        return max(spendable, Value.zeroValue(coinType))
    }

    override var label: String
        get() = accountContext.accountName
        set(value) {
            accountContext.accountName = value
        }

    override fun getBlockChainHeight() = accountContext.blockHeight

    override fun setBlockChainHeight(height: Int) {
        accountContext.blockHeight = height
    }

    override val isArchived
        get() = accountContext.archived

    override val syncTotalRetrievedTransactions: Int = 0 // TODO implement after full transaction history implementation

    override val typicalEstimatedTransactionSize = Transfer.GAS_LIMIT.toInt()

    override fun getPrivateKey(cipher: KeyCipher): InMemoryPrivateKey {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }
}


fun ECKeyPair.toUUID(): UUID = UUID(
        BitUtils.uint64ToLong(publicKey.toByteArray(), 8),
        BitUtils.uint64ToLong(publicKey.toByteArray(), 16))
