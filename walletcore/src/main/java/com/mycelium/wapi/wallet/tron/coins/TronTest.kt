package com.mycelium.wapi.wallet.tron.coins

object TronTest : TronCoin("tron.test", "Tron Test", "tTRX") {
    @JvmStatic
    fun get() = this
}
