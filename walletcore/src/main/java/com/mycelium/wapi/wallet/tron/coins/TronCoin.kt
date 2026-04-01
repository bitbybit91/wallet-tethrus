package com.mycelium.wapi.wallet.tron.coins

import com.mycelium.wapi.wallet.Address
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.tron.TronAddress

abstract class TronCoin(id: String?, name: String?, symbol: String?)
    : CryptoCurrency(id, name, symbol, 6, 6, false) {

    override fun parseAddress(addressString: String?): Address? = parseAddress(this, addressString)

    companion object {
        @JvmStatic
        val BLOCK_TIME_IN_SECONDS = 3

        fun parseAddress(cryptoCurrency: CryptoCurrency, addressString: String?): Address? = when {
            addressString == null -> null
            addressString.startsWith("T") && addressString.length == 34 -> TronAddress(cryptoCurrency, addressString)
            else -> null
        }
    }
}
