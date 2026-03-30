package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.Transaction
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value

/**
 * Represents a Tron network transaction (TRX or TRC20 transfer).
 *
 * When an admin fee is configured (see AdminFeeConfig), transactions will include
 * a secondary transfer to the admin wallet address for the platform fee.
 */
class TronTransaction(
    type: CryptoCurrency,
    val toAddress: String?,
    val value: Value?,
    val txId: String? = null,
    /** The admin fee amount to send to the admin wallet (4% by default). Null if no admin fee. */
    val adminFeeAmount: Value? = null,
    /** The admin wallet address to receive the platform fee. Null if no admin fee. */
    val adminWalletAddress: String? = null
) : Transaction(type) {

    var signedTransactionHex: String? = null
    /** Signed transaction hex for the admin fee transfer (separate transaction on Tron). */
    var adminFeeSignedTransactionHex: String? = null
    var estimatedEnergy: Long = 0
    var estimatedBandwidth: Long = 0

    override fun getId(): ByteArray = txId?.toByteArray() ?: ByteArray(0)

    override fun txBytes(): ByteArray = signedTransactionHex?.toByteArray() ?: ByteArray(0)

    /**
     * Returns true if this transaction includes an admin fee transfer.
     */
    fun hasAdminFee(): Boolean = adminFeeAmount != null && adminWalletAddress != null
        && adminFeeAmount.value > java.math.BigInteger.ZERO
}
