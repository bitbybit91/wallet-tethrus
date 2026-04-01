package com.mycelium.wapi.wallet.trc20.coins

import com.mycelium.wapi.wallet.Address
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.tron.coins.TronCoin

class TRC20Token(
    name: String = "",
    symbol: String = "",
    unitExponent: Int = 6,
    val contractAddress: String
) : CryptoCurrency(name, name, symbol, unitExponent, 6, false) {

    override fun parseAddress(addressString: String?): Address? =
        TronCoin.parseAddress(this, addressString)

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        if (!super.equals(other)) return false

        other as TRC20Token
        if (contractAddress != other.contractAddress) return false

        return true
    }

    override fun hashCode(): Int {
        var result = super.hashCode()
        result = 31 * result + contractAddress.hashCode()
        return result
    }

    companion object {
        val USDT_MAINNET = TRC20Token(
            name = "Tether USD",
            symbol = "USDT",
            unitExponent = 6,
            contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        )

        val USDT_TESTNET = TRC20Token(
            name = "Tether USD test",
            symbol = "tUSDT",
            unitExponent = 6,
            contractAddress = "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf"
        )
    }
}
