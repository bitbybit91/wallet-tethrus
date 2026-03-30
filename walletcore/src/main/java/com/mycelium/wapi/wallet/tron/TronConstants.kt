package com.mycelium.wapi.wallet.tron

/**
 * Centralized constants for the Tron network integration.
 *
 * Contains the TronGrid API key, endpoint URLs, and well-known contract addresses
 * used by [TronGridBlockchainService] and the Tron wallet module.
 */
object TronConstants {

    /** TronGrid API key for higher rate limits */
    const val TRONGRID_API_KEY = "4652ad08-fd86-4ac5-a890-7cefe57124d9"

    /** TronGrid mainnet base URL */
    const val MAINNET_API_URL = "https://api.trongrid.io"

    /** TronGrid Nile testnet base URL */
    const val NILE_TESTNET_API_URL = "https://nile.trongrid.io"

    /** TronGrid Shasta testnet base URL */
    const val SHASTA_TESTNET_API_URL = "https://api.shasta.trongrid.io"

    /** USDT TRC20 contract address on mainnet */
    const val USDT_CONTRACT_ADDRESS = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

    /** USDT TRC20 contract address on Nile testnet */
    const val USDT_NILE_CONTRACT_ADDRESS = "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf"
}
