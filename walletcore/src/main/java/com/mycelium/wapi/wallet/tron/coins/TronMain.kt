package com.mycelium.wapi.wallet.tron.coins

object TronMain : TronCoin("tron.main", "Tron", "TRX") {
    @JvmStatic
    fun get() = this
}
