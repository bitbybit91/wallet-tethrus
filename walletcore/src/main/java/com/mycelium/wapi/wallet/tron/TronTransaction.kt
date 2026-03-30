package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.Transaction
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value

/**
 * Represents a Tron network transaction (TRX or TRC20 transfer).
 */
class TronTransaction(
    type: CryptoCurrency,
    val toAddress: String?,
    val value: Value?,
    val txId: String? = null
) : Transaction(type) {

    var signedTransactionHex: String? = null
    var estimatedEnergy: Long = 0
    var estimatedBandwidth: Long = 0

    override fun getId(): ByteArray = txId?.toByteArray() ?: ByteArray(0)

    override fun txBytes(): ByteArray = signedTransactionHex?.toByteArray() ?: ByteArray(0)
}
