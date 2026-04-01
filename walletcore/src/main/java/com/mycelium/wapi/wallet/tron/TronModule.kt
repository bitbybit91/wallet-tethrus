package com.mycelium.wapi.wallet.tron

import com.mrd.bitlib.model.NetworkParameters
import com.mrd.bitlib.model.hdpath.HdKeyPath
import com.mycelium.generated.wallet.database.WalletDB
import com.mycelium.wapi.wallet.AccountListener
import com.mycelium.wapi.wallet.CurrencySettings
import com.mycelium.wapi.wallet.KeyCipher
import com.mycelium.wapi.wallet.SecureKeyValueStore
import com.mycelium.wapi.wallet.WalletAccount
import com.mycelium.wapi.wallet.WalletManager
import com.mycelium.wapi.wallet.genericdb.Backing
import com.mycelium.wapi.wallet.manager.Config
import com.mycelium.wapi.wallet.manager.WalletModule
import com.mycelium.wapi.wallet.metadata.IMetaDataStorage
import com.mycelium.wapi.wallet.tron.coins.TronMain
import com.mycelium.wapi.wallet.tron.coins.TronTest
import java.util.UUID

class TronModule(
    private val secureStore: SecureKeyValueStore,
    private val backing: Backing<TronAccountContext>,
    private val walletDB: WalletDB,
    private val networkParameters: NetworkParameters,
    metaDataStorage: IMetaDataStorage,
    private val accountListener: AccountListener?,
    private val tronGridApiUrl: String,
    private val tronScanExplorerUrl: String,
    private val tronUsdtContract: String
) : WalletModule(metaDataStorage) {

    var settings: TronSettings = TronSettings()
    val coinType = if (networkParameters.isProdnet) TronMain else TronTest
    private val accounts = mutableMapOf<UUID, WalletAccount<*>>()
    override val id = ID

    init {
        assetsList.add(coinType)
    }

    fun getBip44Path(accountIndex: Int): HdKeyPath =
        HdKeyPath.valueOf("m/44'/195'/$accountIndex'/0/0")

    override fun getAccountById(id: UUID): WalletAccount<*>? = accounts[id]

    override fun setCurrencySettings(currencySettings: CurrencySettings) {
        this.settings = currencySettings as TronSettings
    }

    override fun getAccounts(): List<WalletAccount<*>> = accounts.values.toList()

    override fun loadAccounts(): Map<UUID, WalletAccount<*>> = emptyMap()

    override fun canCreateAccount(config: Config) =
        config is TronMasterseedConfig || config is TronAddressConfig

    override fun createAccount(config: Config): WalletAccount<*> {
        throw UnsupportedOperationException("Tron account creation requires full node connectivity")
    }

    override fun deleteAccount(walletAccount: WalletAccount<*>, keyCipher: KeyCipher): Boolean {
        accounts.remove(walletAccount.id)
        return true
    }

    private fun getCurrentBip44Index() = accounts.values
        .filter { it.isDerivedFromInternalMasterseed() }
        .maxByOrNull { it.id.hashCode() }
        ?.let { 0 }
        ?: -1

    companion object {
        const val ID: String = "Tron"

        fun publicKeyToTronAddress(publicKeyBytes: ByteArray): String {
            val hash = org.web3j.crypto.Hash.sha3(publicKeyBytes.drop(1).toByteArray())
            val addressBytes = ByteArray(21)
            addressBytes[0] = 0x41
            System.arraycopy(hash, 12, addressBytes, 1, 20)
            val checksum = sha256(sha256(addressBytes))
            val fullAddress = addressBytes + checksum.take(4).toByteArray()
            return com.mrd.bitlib.bitcoinj.Base58.encode(fullAddress)
        }

        private fun sha256(input: ByteArray): ByteArray {
            val digest = java.security.MessageDigest.getInstance("SHA-256")
            return digest.digest(input)
        }
    }
}

fun WalletManager.getTronAccounts() = getAccounts().filter {
    it.coinType.id == TronMain.id || it.coinType.id == TronTest.id
}
