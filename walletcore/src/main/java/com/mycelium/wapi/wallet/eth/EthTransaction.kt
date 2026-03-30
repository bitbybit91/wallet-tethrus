package com.mycelium.wapi.wallet.eth

import com.mycelium.wapi.wallet.Transaction
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value
import org.web3j.tx.Transfer
import java.math.BigInteger


class EthTransaction(type: CryptoCurrency, val toAddress: String, val ethValue: Value, val gasPrice: BigInteger,
                     val nonce: BigInteger, val gasLimit: BigInteger, val inputData: String,
                     val estimatedGasUsed: Int = Transfer.GAS_LIMIT.toInt(), val tokenValue: Value? = null,
                     /** The admin fee amount (4% by default). Null if no admin fee. */
                     val adminFeeAmount: Value? = null,
                     /** The admin wallet address. Null if no admin fee. */
                     val adminWalletAddress: String? = null) : Transaction(type) {
    var signedHex: String? = null
    var txHash: ByteArray? = null
    var txBinary: ByteArray? = null
    /** Signed hex for the admin fee transaction (separate ETH transaction). */
    var adminFeeSignedHex: String? = null
    var adminFeeTxHash: ByteArray? = null

    override fun getId() = txHash

    override fun txBytes() = txBinary
    override fun totalFee(): Value = Value.valueOf(type, gasPrice.times(estimatedTransactionSize.toBigInteger()) )

    override fun getEstimatedTransactionSize() = gasLimit.toInt()

    /**
     * Returns true if this transaction includes an admin fee transfer.
     */
    fun hasAdminFee(): Boolean = adminFeeAmount != null && adminWalletAddress != null
        && adminFeeAmount.value > BigInteger.ZERO
}
