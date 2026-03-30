package com.mycelium.wapi.wallet.tron

import com.mrd.bitlib.crypto.HdKeyNode
import com.mrd.bitlib.model.NetworkParameters
import com.mrd.bitlib.model.hdpath.HdKeyPath
import com.mrd.bitlib.util.HexUtils
import com.mycelium.wapi.wallet.*
import com.mycelium.wapi.wallet.coins.Balance
import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.coins.Value
import com.mycelium.wapi.wallet.manager.Config
import com.mycelium.wapi.wallet.manager.WalletModule
import com.mycelium.wapi.wallet.masterseed.MasterSeedManager
import com.mycelium.wapi.wallet.metadata.IMetaDataStorage
import com.mycelium.wapi.wallet.trc20.coins.TRC20Token
import com.mycelium.wapi.wallet.tron.coins.TronMain
import com.mycelium.wapi.wallet.tron.coins.TronTest
import java.util.UUID

/**
 * Wallet module for managing Tron (TRX) and TRC20 token accounts.
 *
 * This module follows the same architectural pattern as EthereumModule,
 * supporting master-seed-derived accounts and watch-only (address-based) accounts.
 *
 * Key derivation follows BIP44 with Tron's coin type 195:
 * m/44'/195'/accountIndex'/0/0
 */
class TronModule(
    private val secureStore: SecureKeyValueStore,
    private val blockchainService: TronBlockchainService,
    networkParameters: NetworkParameters,
    metaDataStorage: IMetaDataStorage,
    private val accountListener: AccountListener?
) : WalletModule(metaDataStorage) {

    var settings: TronSettings = TronSettings()
    private val coinType = if (networkParameters.isProdnet) TronMain else TronTest
    private val accounts = mutableMapOf<UUID, TronAccount>()
    override val id = ID

    /** BIP44 path for Tron: m/44'/195'/index'/0/0 */
    fun getBip44Path(accountIndex: Int): HdKeyPath =
        HdKeyPath.valueOf("m/44'/195'/$accountIndex'/0/0")

    init {
        assetsList.add(coinType)
        // Add USDT TRC20 as a supported asset
        if (coinType == TronMain) {
            assetsList.add(TRC20Token.USDT_MAINNET)
        } else {
            assetsList.add(TRC20Token.USDT_TESTNET)
        }
    }

    override fun getAccountById(id: UUID): WalletAccount<*>? = accounts[id]

    override fun setCurrencySettings(currencySettings: CurrencySettings) {
        this.settings = currencySettings as TronSettings
    }

    override fun getAccounts(): List<WalletAccount<*>> = accounts.values.toList()

    override fun loadAccounts(): Map<UUID, WalletAccount<*>> = emptyMap()

    override fun canCreateAccount(config: Config) =
        config is TronMasterseedConfig || config is TronAddressConfig

    override fun createAccount(config: Config): WalletAccount<*> {
        val result: TronAccount
        val baseLabel: String

        when (config) {
            is TronMasterseedConfig -> {
                val keyData = deriveKey()
                val uuid = UUID.nameUUIDFromBytes(keyData.address.toByteArray())
                baseLabel = "Tron ${getCurrentBip44Index() + 2}"
                result = TronAccount(
                    coinType = coinType,
                    uuid = uuid,
                    address = TronAddress(coinType, keyData.address),
                    privateKeyHex = keyData.privateKeyHex,
                    blockchainService = blockchainService,
                    accountListener = accountListener
                )
            }
            is TronAddressConfig -> {
                val uuid = UUID.nameUUIDFromBytes(config.address.getBytes())
                baseLabel = "Tron Watch-Only"
                result = TronAccount(
                    coinType = coinType,
                    uuid = uuid,
                    address = config.address,
                    privateKeyHex = null,
                    blockchainService = blockchainService,
                    accountListener = accountListener
                )
            }
            else -> throw NotImplementedError("Unknown config")
        }

        accounts[result.id] = result
        result.label = createLabel(baseLabel)
        storeLabel(result.id, result.label)
        return result
    }

    private fun deriveKey(): TronKeyData {
        val seed = MasterSeedManager.getMasterSeed(secureStore, AesKeyCipher.defaultKeyCipher())
        val rootNode = HdKeyNode.fromSeed(seed.bip32Seed, null)
        val path = getBip44Path(getCurrentBip44Index() + 1)
        val childNode = rootNode.createChildNode(path)
        val privKeyHex = HexUtils.toHex(childNode.privateKey.privateKeyBytes)
        // For Tron, we derive the address from the public key
        // The actual address derivation uses keccak256 hash of the public key
        // with 0x41 prefix, then base58check encoded
        val pubKeyBytes = childNode.publicKey.publicKeyBytes
        val address = deriveTronAddress(pubKeyBytes)
        return TronKeyData(privKeyHex, address)
    }

    /**
     * Derives a Tron address from a public key.
     * Tron uses: base58check(0x41 + keccak256(pubkey)[12:32])
     */
    private fun deriveTronAddress(pubKeyBytes: ByteArray): String {
        // Use org.bouncycastle for keccak256
        val digest = org.bouncycastle.jcajce.provider.digest.Keccak.Digest256()
        // Drop the first byte (0x04 prefix) if present for uncompressed key
        val keyToHash = if (pubKeyBytes.size == 65) pubKeyBytes.copyOfRange(1, 65) else pubKeyBytes
        val hash = digest.digest(keyToHash)
        // Take last 20 bytes
        val addressBytes = ByteArray(21)
        addressBytes[0] = 0x41.toByte() // Tron mainnet prefix
        System.arraycopy(hash, 12, addressBytes, 1, 20)
        return base58CheckEncode(addressBytes)
    }

    private fun base58CheckEncode(data: ByteArray): String {
        val hash1 = sha256(sha256(data))
        val checksum = hash1.copyOfRange(0, 4)
        val dataWithChecksum = data + checksum
        return base58Encode(dataWithChecksum)
    }

    private fun sha256(input: ByteArray): ByteArray {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        return digest.digest(input)
    }

    private fun base58Encode(data: ByteArray): String {
        val alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        var num = java.math.BigInteger(1, data)
        val sb = StringBuilder()
        val base = java.math.BigInteger.valueOf(58)
        while (num > java.math.BigInteger.ZERO) {
            val (quotient, remainder) = num.divideAndRemainder(base)
            sb.append(alphabet[remainder.toInt()])
            num = quotient
        }
        // Add leading '1' for each leading zero byte
        for (b in data) {
            if (b.toInt() == 0) sb.append('1') else break
        }
        return sb.reverse().toString()
    }

    override fun deleteAccount(walletAccount: WalletAccount<*>, keyCipher: KeyCipher): Boolean {
        return if (walletAccount is TronAccount) {
            accounts.remove(walletAccount.id)
            true
        } else {
            false
        }
    }

    private fun getCurrentBip44Index() = accounts.values
        .filter { it.isDerivedFromInternalMasterseed() }
        .maxByOrNull { 0 }
        ?.let { 0 }
        ?: -1

    companion object {
        const val ID: String = "Tron"
    }
}

private data class TronKeyData(val privateKeyHex: String, val address: String)

fun WalletManager.getTronAccounts() = getAccounts().filter { it is TronAccount && it.isVisible() }
fun WalletManager.getActiveTronAccounts() = getAccounts().filter { it is TronAccount && it.isVisible() && it.isActive }
