package com.mycelium.wapi.wallet.adminfee

import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value
import java.math.BigInteger
import java.math.RoundingMode

/**
 * Manages the calculation of admin fees for outgoing transactions.
 *
 * The admin fee is a platform fee (default 4%) that is deducted from the user's
 * total send amount and automatically directed to the admin wallet address.
 *
 * Usage in the send flow:
 * 1. User specifies total amount to send (e.g., 100 USDT)
 * 2. AdminFeeManager.calculateAdminFee(100 USDT) → returns 4 USDT
 * 3. AdminFeeManager.calculateRecipientAmount(100 USDT) → returns 96 USDT
 * 4. Transaction is built with two outputs: 96 USDT to recipient + 4 USDT to admin wallet
 *    OR: Two separate transactions are created if the blockchain doesn't support multi-output.
 */
object AdminFeeManager {

    /**
     * Calculate the admin fee for a given transaction amount.
     *
     * @param totalAmount The total amount the user wants to send
     * @return The admin fee portion (4% by default)
     */
    fun calculateAdminFee(totalAmount: Value): Value {
        if (!AdminFeeConfig.isEnabled) {
            return Value.zeroValue(totalAmount.type)
        }
        val feeAmount = totalAmount.value
            .toBigDecimal()
            .multiply(AdminFeeConfig.ADMIN_FEE_FRACTION.toBigDecimal())
            .setScale(0, RoundingMode.FLOOR)
            .toBigInteger()
        return Value.valueOf(totalAmount.type, feeAmount)
    }

    /**
     * Calculate the amount that the recipient will receive after deducting the admin fee.
     *
     * @param totalAmount The total amount the user wants to send
     * @return The amount the recipient gets (totalAmount - adminFee)
     */
    fun calculateRecipientAmount(totalAmount: Value): Value {
        if (!AdminFeeConfig.isEnabled) {
            return totalAmount
        }
        val adminFee = calculateAdminFee(totalAmount)
        val recipientAmount = totalAmount.value.subtract(adminFee.value)
        // Ensure we don't go negative
        if (recipientAmount < BigInteger.ZERO) {
            return Value.zeroValue(totalAmount.type)
        }
        return Value.valueOf(totalAmount.type, recipientAmount)
    }

    /**
     * Get the admin wallet address for the given coin type.
     *
     * @param coinType The cryptocurrency type
     * @param isTestnet Whether we're on a testnet
     * @return The admin wallet address string, or null if no admin wallet is configured
     */
    fun getAdminWalletAddress(coinType: CryptoCurrency, isTestnet: Boolean = false): String? {
        if (!AdminFeeConfig.isEnabled) {
            return null
        }
        val coinId = coinType.id.lowercase()
        return when {
            coinId.contains("tron") || coinId.contains("trc20") || coinId.contains("usdt") -> {
                if (isTestnet) AdminFeeConfig.ADMIN_WALLET_TRC20_TESTNET
                else AdminFeeConfig.ADMIN_WALLET_TRC20_MAINNET
            }
            coinId.contains("eth") || coinId.contains("erc20") -> {
                AdminFeeConfig.ADMIN_WALLET_ETH
            }
            coinId.contains("btc") || coinId.contains("bitcoin") -> {
                AdminFeeConfig.ADMIN_WALLET_BTC
            }
            else -> null
        }
    }

    /**
     * Returns true if an admin fee should be applied for the given coin type.
     */
    fun shouldApplyFee(coinType: CryptoCurrency): Boolean {
        return AdminFeeConfig.isEnabled && getAdminWalletAddress(coinType) != null
    }

    /**
     * Returns the fee percentage for display purposes.
     */
    fun getFeePercentage(): Double = AdminFeeConfig.ADMIN_FEE_PERCENT

    /**
     * Format the admin fee information for display in the send confirmation screen.
     *
     * @param totalAmount The total amount being sent
     * @return A human-readable string describing the fee breakdown
     */
    fun formatFeeBreakdown(totalAmount: Value): String {
        val adminFee = calculateAdminFee(totalAmount)
        val recipientAmount = calculateRecipientAmount(totalAmount)
        return "Recipient receives: $recipientAmount, Platform fee (${AdminFeeConfig.ADMIN_FEE_PERCENT}%): $adminFee"
    }
}
