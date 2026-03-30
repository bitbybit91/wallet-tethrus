package com.mycelium.wapi.wallet.tron

import com.mrd.bitlib.model.hdpath.HdKeyPath
import com.mycelium.wapi.wallet.Address
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import java.io.IOException
import java.io.ObjectInputStream

/**
 * Represents a Tron (TRX) network address.
 *
 * Tron addresses are Base58Check encoded with a 0x41 prefix on mainnet,
 * and always start with the letter 'T'. They are 34 characters long.
 */
class TronAddress(cryptoCurrency: CryptoCurrency, val addressString: String) : Address {

    override val coinType = cryptoCurrency

    override fun getSubType() = "default"

    override fun getBytes() = addressString.toByteArray()

    override fun toString() = addressString

    override fun equals(other: Any?): Boolean {
        if (other !is TronAddress) {
            return false
        }
        return addressString == other.addressString
    }

    override fun hashCode(): Int {
        return addressString.hashCode()
    }

    private var _bip32Path: HdKeyPath? = null
    override fun getBip32Path(): HdKeyPath? = _bip32Path

    override fun setBip32Path(bip32Path: HdKeyPath?) {
        _bip32Path = bip32Path
    }

    companion object {
        /**
         * Validates a Tron address string.
         * Tron mainnet addresses start with 'T' and are 34 characters of Base58.
         */
        fun isValidAddress(address: String): Boolean {
            if (address.length != 34) return false
            if (!address.startsWith("T")) return false
            // Base58 character set validation
            val base58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
            return address.all { it in base58Chars }
        }

        fun getDummyAddress(cryptoCurrency: CryptoCurrency) =
            TronAddress(cryptoCurrency, "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb")
    }
}
