package com.tethrus.wallet.tron

/**
 * TRC-20 token descriptor.
 *
 * @param contractAddress Base58check-encoded TRON contract address.
 * @param symbol          Token ticker (e.g. "USDT").
 * @param decimals        Number of decimal places (e.g. 6 for USDT-TRC20).
 * @param name            Human-readable token name (e.g. "Tether USD").
 */
data class Trc20Token(
    val contractAddress: String,
    val symbol: String,
    val decimals: Int,
    val name: String
) {
    companion object {
        /** Canonical USDT-TRC20 token on TRON mainnet. */
        val USDT_MAINNET = Trc20Token(
            contractAddress = TronNetworkEndpoints.MAINNET_USDT,
            symbol = "USDT",
            decimals = 6,
            name = "Tether USD"
        )

        /** Canonical USDT-TRC20 token on the Nile testnet. */
        val USDT_NILE = Trc20Token(
            contractAddress = TronNetworkEndpoints.NILE_USDT,
            symbol = "USDT",
            decimals = 6,
            name = "Tether USD"
        )
    }
}
