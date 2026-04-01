package com.mycelium.wapi.wallet.tron

import com.mrd.bitlib.model.hdpath.HdKeyPath
import com.mycelium.wapi.wallet.Address
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import java.io.IOException
import java.io.ObjectInputStream

class TronAddress(cryptoCurrency: CryptoCurrency, val addressString: String) : Address {
    override val coinType = cryptoCurrency

    override fun getSubType() = "default"

    override fun getBytes() = addressString.toByteArray()

    override fun toString() = addressString

    @Throws(ClassNotFoundException::class, IOException::class)
    private fun readObject(inputStream: ObjectInputStream) {
        inputStream.defaultReadObject()
    }

    override fun equals(other: Any?): Boolean {
        if (other !is TronAddress) {
            return false
        }
        return addressString == other.addressString
    }

    override fun hashCode(): Int {
        return addressString.hashCode()
    }

    companion object {
        fun getDummyAddress(cryptoCurrency: CryptoCurrency) =
            TronAddress(cryptoCurrency, "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb")
    }

    private var _bip32Path: HdKeyPath? = null
    override fun getBip32Path(): HdKeyPath? = _bip32Path

    override fun setBip32Path(bip32Path: HdKeyPath?) {
        _bip32Path = bip32Path
    }
}
