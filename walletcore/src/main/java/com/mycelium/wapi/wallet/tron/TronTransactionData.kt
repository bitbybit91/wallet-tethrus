package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.TransactionData

/**
 * Data required to construct a Tron transaction.
 * Contains recipient address, amount, and optional TRC20 contract info.
 */
data class TronTransactionData(
    val recipientAddress: String,
    val amount: Long,
    val contractAddress: String? = null,
    val memo: String? = null
) : TransactionData {
    val isTrc20Transfer: Boolean
        get() = contractAddress != null
}
