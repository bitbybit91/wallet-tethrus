package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.coins.Balance
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.genericdb.AccountContextImpl
import java.util.UUID

class TronAccountContext(
    uuid: UUID,
    currency: CryptoCurrency,
    accountName: String,
    balance: Balance,
    val listener: (TronAccountContext) -> Unit,
    val accountIndex: Int,
    archived: Boolean = false,
    blockHeight: Int = 0
) : AccountContextImpl(uuid, currency, accountName, balance, archived, blockHeight) {

    override fun onChange() {
        listener(this)
    }
}
