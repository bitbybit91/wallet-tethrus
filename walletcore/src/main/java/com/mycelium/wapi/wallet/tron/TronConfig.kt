package com.mycelium.wapi.wallet.tron

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
 *
 * CurrencySettings is a marker interface with no methods.
 */
class TronSettings : com.mycelium.wapi.wallet.CurrencySettings
