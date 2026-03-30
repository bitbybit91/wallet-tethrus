package com.mycelium.wapi.wallet.adminfee

/**
 * Configuration for the platform admin fee applied to all outgoing trades and deposits.
 *
 * A configurable percentage of every outgoing transaction is automatically sent to the
 * admin wallet address. The fee is deducted from the user's send amount, so the total
 * sent from the wallet equals (userAmount + adminFee).
 *
 * The admin wallet addresses can be updated without recompilation by modifying the
 * constants below or by loading them from a remote configuration endpoint.
 *
 * Example with 4% fee:
 *   User sends 100 USDT → recipient gets 96 USDT, admin wallet gets 4 USDT
 *   Total deducted from sender: 100 USDT
 */
object AdminFeeConfig {

    /**
     * Admin fee percentage as a decimal fraction.
     * 0.04 = 4% of the transaction amount is sent to the admin wallet.
     */
    const val ADMIN_FEE_FRACTION: Double = 0.04

    /**
     * Admin fee percentage for display purposes.
     */
    const val ADMIN_FEE_PERCENT: Double = 4.0

    /**
     * Admin wallet address for USDT-TRC20 on Tron Mainnet.
     * This is the address that receives the 4% admin fee from all trades and deposits.
     *
     * !! CONFIGURATION REQUIRED !!
     * Replace this placeholder with your actual admin Tron wallet address before publishing.
     * The address must be a valid Tron base58 address starting with 'T' and 34 characters long.
     * Example: "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb"
     */
    var ADMIN_WALLET_TRC20_MAINNET: String = "TYouRAdMinWaLLeTAddreSsForMainNet41"

    /**
     * Admin wallet address for USDT-TRC20 on Tron Nile Testnet.
     *
     * !! CONFIGURATION REQUIRED !!
     * Replace this placeholder with your actual testnet admin wallet address.
     * The address must be a valid Tron base58 address starting with 'T' and 34 characters long.
     */
    var ADMIN_WALLET_TRC20_TESTNET: String = "TYouRAdMinWaLLeTAddreSsForTestNet42"

    /**
     * Admin wallet address for Ethereum (ETH and ERC20 tokens).
     *
     * !! CONFIGURATION REQUIRED !!
     * Replace this placeholder with your actual admin Ethereum wallet address.
     * The address must be a valid Ethereum hex address (42 chars including 0x prefix).
     * Example: "0x742d35Cc6634C0532925a3b844Bc9e7595f2bD3e"
     */
    var ADMIN_WALLET_ETH: String = "0xYourAdminEthWalletAddressHere000000000000"

    /**
     * Admin wallet address for Bitcoin.
     *
     * !! CONFIGURATION REQUIRED !!
     * Replace this placeholder with your actual admin Bitcoin wallet address.
     * Supports legacy (1...), P2SH (3...), or bech32 (bc1...) formats.
     * Example: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
     */
    var ADMIN_WALLET_BTC: String = "bc1qYourAdminBtcWalletAddressHere000000"

    /**
     * Whether the admin fee is enabled. Can be toggled for testing.
     */
    var isEnabled: Boolean = true
}
