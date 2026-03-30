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
     * IMPORTANT: Replace this with your actual admin Tron wallet address before publishing.
     */
    var ADMIN_WALLET_TRC20_MAINNET: String = "TYouRAdMinWaLLeTAddreSsForMainNet41"

    /**
     * Admin wallet address for USDT-TRC20 on Tron Nile Testnet.
     *
     * IMPORTANT: Replace this with your actual testnet admin wallet address.
     */
    var ADMIN_WALLET_TRC20_TESTNET: String = "TYouRAdMinWaLLeTAddreSsForTestNet42"

    /**
     * Admin wallet address for Ethereum (ETH and ERC20 tokens).
     *
     * IMPORTANT: Replace this with your actual admin Ethereum wallet address.
     */
    var ADMIN_WALLET_ETH: String = "0xYourAdminEthWalletAddressHere000000000000"

    /**
     * Admin wallet address for Bitcoin.
     *
     * IMPORTANT: Replace this with your actual admin Bitcoin wallet address.
     */
    var ADMIN_WALLET_BTC: String = "bc1qYourAdminBtcWalletAddressHere000000"

    /**
     * Whether the admin fee is enabled. Can be toggled for testing.
     */
    var isEnabled: Boolean = true
}
