package com.tethrus.wallet.tron

import java.math.BigDecimal
import java.math.BigInteger

/**
 * Encapsulates a TRON account with its native TRX balance and TRC-20 token balances.
 *
 * @param address         Base58check-encoded TRON address.
 * @param trxBalanceSun   Raw TRX balance in SUN (1 TRX = 1_000_000 SUN).
 * @param trc20Balances   Map of TRC-20 token → raw integer balance (in the token's smallest unit).
 * @param bandwidth       Available bandwidth for this account (may be 0 if unknown).
 * @param energy          Available energy for this account (may be 0 if unknown).
 */
data class TronAccount(
    val address: String,
    val trxBalanceSun: BigInteger,
    val trc20Balances: Map<Trc20Token, BigInteger> = emptyMap(),
    val bandwidth: Long = 0L,
    val energy: Long = 0L
) {
    /** TRX balance expressed as a human-readable decimal (divided by 1_000_000). */
    val trxBalance: BigDecimal
        get() = BigDecimal(trxBalanceSun).movePointLeft(6)

    /**
     * Returns the human-readable balance for the given [token], accounting for its [Trc20Token.decimals].
     * Returns [BigDecimal.ZERO] when the token is not present in [trc20Balances].
     */
    fun getTokenBalance(token: Trc20Token): BigDecimal {
        val raw = trc20Balances[token] ?: return BigDecimal.ZERO
        return BigDecimal(raw).movePointLeft(token.decimals)
    }

    /**
     * Returns [true] when this account holds a non-zero balance of [token].
     */
    fun hasToken(token: Trc20Token): Boolean =
        (trc20Balances[token] ?: BigInteger.ZERO) > BigInteger.ZERO

    companion object {
        /** Placeholder representing an account that has not yet been fetched. */
        fun empty(address: String) = TronAccount(
            address = address,
            trxBalanceSun = BigInteger.ZERO
        )
    }
}
