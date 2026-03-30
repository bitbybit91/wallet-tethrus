package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.coins.CryptoCurrency

/**
 * Configuration for creating a Tron account from the master seed.
 */
class TronMasterseedConfig : com.mycelium.wapi.wallet.manager.Config

/**
 * Configuration for adding a Tron account by address (watch-only).
 */
class TronAddressConfig(val address: TronAddress) : com.mycelium.wapi.wallet.manager.Config

/**
 * Settings specific to the Tron network module.
 */
class TronSettings : com.mycelium.wapi.wallet.CurrencySettings {
    override fun getDefaultCurrency(): CryptoCurrency? = null
}
