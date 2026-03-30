package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.tron.coins.TronMain
import com.mycelium.wapi.wallet.tron.coins.TronTest
import com.mycelium.wapi.wallet.trc20.coins.TRC20Token
import org.junit.Assert.*
import org.junit.Test

class TronAddressTest {

    @Test
    fun `valid mainnet Tron address is accepted`() {
        // USDT TRC20 contract address (well-known mainnet address)
        assertTrue(TronAddress.isValidAddress("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"))
    }

    @Test
    fun `valid testnet Tron address is accepted`() {
        assertTrue(TronAddress.isValidAddress("TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf"))
    }

    @Test
    fun `dummy address is valid`() {
        assertTrue(TronAddress.isValidAddress("T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb"))
    }

    @Test
    fun `address too short is rejected`() {
        assertFalse(TronAddress.isValidAddress("T9yD14Nj9j7xAB4dbGeiX9h8unk"))
    }

    @Test
    fun `address too long is rejected`() {
        assertFalse(TronAddress.isValidAddress("T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwbXXXX"))
    }

    @Test
    fun `address not starting with T is rejected`() {
        assertFalse(TronAddress.isValidAddress("19yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb"))
    }

    @Test
    fun `empty address is rejected`() {
        assertFalse(TronAddress.isValidAddress(""))
    }

    @Test
    fun `address with invalid characters is rejected`() {
        // '0', 'O', 'I', 'l' are not in Base58 alphabet
        assertFalse(TronAddress.isValidAddress("T0yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb"))
    }

    @Test
    fun `Bitcoin address is rejected`() {
        assertFalse(TronAddress.isValidAddress("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"))
    }

    @Test
    fun `Ethereum address is rejected`() {
        assertFalse(TronAddress.isValidAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f2bD3e"))
    }

    @Test
    fun `TronAddress toString returns address string`() {
        val address = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertEquals("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", address.toString())
    }

    @Test
    fun `TronAddress equals works correctly`() {
        val addr1 = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        val addr2 = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        val addr3 = TronAddress(TronMain, "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf")
        assertEquals(addr1, addr2)
        assertNotEquals(addr1, addr3)
    }

    @Test
    fun `TronMain coin type is configured correctly`() {
        assertEquals("tron.main", TronMain.id)
        assertEquals("Tron", TronMain.name)
        assertEquals("TRX", TronMain.symbol)
        assertEquals(6, TronMain.unitExponent)
        assertEquals(6, TronMain.friendlyDigits)
        assertFalse(TronMain.isUtxosBased)
    }

    @Test
    fun `TronTest coin type is configured correctly`() {
        assertEquals("tron.test", TronTest.id)
        assertEquals("Tron Test", TronTest.name)
        assertEquals("tTRX", TronTest.symbol)
        assertEquals(6, TronTest.unitExponent)
        assertFalse(TronTest.isUtxosBased)
    }

    @Test
    fun `TRC20Token USDT mainnet is configured correctly`() {
        val usdt = TRC20Token.USDT_MAINNET
        assertEquals("Tether USD", usdt.name)
        assertEquals("USDT", usdt.symbol)
        assertEquals(6, usdt.unitExponent)
        assertEquals("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", usdt.contractAddress)
        assertFalse(usdt.isUtxosBased)
    }

    @Test
    fun `TRC20Token USDT testnet is configured correctly`() {
        val usdt = TRC20Token.USDT_TESTNET
        assertEquals("Tether USD Test", usdt.name)
        assertEquals("tUSDT", usdt.symbol)
        assertEquals(6, usdt.unitExponent)
        assertEquals("TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf", usdt.contractAddress)
    }

    @Test
    fun `TronCoin parseAddress returns valid address`() {
        val address = TronMain.parseAddress("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertNotNull(address)
        assertTrue(address is TronAddress)
        assertEquals("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", address.toString())
    }

    @Test
    fun `TronCoin parseAddress returns null for invalid address`() {
        val address = TronMain.parseAddress("invalid_address")
        assertNull(address)
    }

    @Test
    fun `TronCoin parseAddress returns null for null`() {
        val address = TronMain.parseAddress(null)
        assertNull(address)
    }

    @Test
    fun `TRC20Token parseAddress returns valid address`() {
        val address = TRC20Token.USDT_MAINNET.parseAddress("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertNotNull(address)
        assertTrue(address is TronAddress)
    }

    @Test
    fun `TronAddress getBytes returns address bytes`() {
        val address = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertArrayEquals("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t".toByteArray(), address.getBytes())
    }

    @Test
    fun `TronAddress coinType returns correct type`() {
        val address = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertEquals(TronMain, address.coinType)
    }

    @Test
    fun `TronAddress subType is default`() {
        val address = TronAddress(TronMain, "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        assertEquals("default", address.getSubType())
    }
}
