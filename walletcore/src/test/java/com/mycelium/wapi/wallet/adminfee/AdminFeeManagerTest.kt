package com.mycelium.wapi.wallet.adminfee

import com.mycelium.wapi.wallet.coins.Value
import com.mycelium.wapi.wallet.tron.coins.TronMain
import com.mycelium.wapi.wallet.tron.coins.TronTest
import com.mycelium.wapi.wallet.trc20.coins.TRC20Token
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.math.BigInteger

class AdminFeeManagerTest {

    @Before
    fun setUp() {
        // Reset admin fee state before each test
        AdminFeeConfig.isEnabled = true
        AdminFeeConfig.ADMIN_FEE_FRACTION = 0.04
    }

    @Test
    fun `calculateAdminFee returns 4 percent of 100 USDT`() {
        // 100 USDT = 100,000,000 micro-units (6 decimals)
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.valueOf(4_000_000L), fee.value)
    }

    @Test
    fun `calculateAdminFee returns 4 percent of 1000 USDT`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 1_000_000_000L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.valueOf(40_000_000L), fee.value)
    }

    @Test
    fun `calculateAdminFee returns 4 percent of 1 USDT`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 1_000_000L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.valueOf(40_000L), fee.value)
    }

    @Test
    fun `calculateAdminFee floors to avoid overpaying on small amounts`() {
        // 1 micro-unit - 4% = 0.04, floor to 0
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 1L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.ZERO, fee.value)
    }

    @Test
    fun `calculateRecipientAmount returns 96 percent of 100 USDT`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(amount)
        assertEquals(BigInteger.valueOf(96_000_000L), recipientAmount.value)
    }

    @Test
    fun `calculateRecipientAmount plus adminFee equals original amount`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(amount)
        val adminFee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(amount.value, recipientAmount.value.add(adminFee.value))
    }

    @Test
    fun `calculateRecipientAmount plus adminFee equals original for 50 USDT`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 50_000_000L)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(amount)
        val adminFee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(amount.value, recipientAmount.value.add(adminFee.value))
    }

    @Test
    fun `fee is zero when disabled`() {
        AdminFeeConfig.isEnabled = false
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.ZERO, fee.value)
    }

    @Test
    fun `recipient gets full amount when fee is disabled`() {
        AdminFeeConfig.isEnabled = false
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val recipientAmount = AdminFeeManager.calculateRecipientAmount(amount)
        assertEquals(amount.value, recipientAmount.value)
    }

    @Test
    fun `getAdminWalletAddress returns mainnet address for TronMain`() {
        val address = AdminFeeManager.getAdminWalletAddress(TronMain, isTestnet = false)
        assertNotNull(address)
        assertEquals(AdminFeeConfig.ADMIN_WALLET_TRC20_MAINNET, address)
    }

    @Test
    fun `getAdminWalletAddress returns testnet address for TronTest`() {
        val address = AdminFeeManager.getAdminWalletAddress(TronTest, isTestnet = true)
        assertNotNull(address)
        assertEquals(AdminFeeConfig.ADMIN_WALLET_TRC20_TESTNET, address)
    }

    @Test
    fun `getAdminWalletAddress returns null when fee disabled`() {
        AdminFeeConfig.isEnabled = false
        val address = AdminFeeManager.getAdminWalletAddress(TronMain)
        assertNull(address)
    }

    @Test
    fun `shouldApplyFee returns true for TronMain`() {
        assertTrue(AdminFeeManager.shouldApplyFee(TronMain))
    }

    @Test
    fun `shouldApplyFee returns false when disabled`() {
        AdminFeeConfig.isEnabled = false
        assertFalse(AdminFeeManager.shouldApplyFee(TronMain))
    }

    @Test
    fun `getFeePercentage returns 4`() {
        assertEquals(4.0, AdminFeeManager.getFeePercentage(), 0.001)
    }

    @Test
    fun `admin fee for TRX amount is correct`() {
        // 100 TRX = 100,000,000 SUN (6 decimals)
        val amount = Value.valueOf(TronMain, 100_000_000L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.valueOf(4_000_000L), fee.value)
    }

    @Test
    fun `admin fee for zero amount is zero`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 0L)
        val fee = AdminFeeManager.calculateAdminFee(amount)
        assertEquals(BigInteger.ZERO, fee.value)
    }

    @Test
    fun `formatFeeBreakdown contains recipient and fee info`() {
        val amount = Value.valueOf(TRC20Token.USDT_MAINNET, 100_000_000L)
        val breakdown = AdminFeeManager.formatFeeBreakdown(amount)
        assertTrue(breakdown.contains("Recipient receives"))
        assertTrue(breakdown.contains("Platform fee"))
        assertTrue(breakdown.contains("4.0%"))
    }
}
