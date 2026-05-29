package com.mycelium.wapi.wallet.eth

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import org.web3j.crypto.Credentials
import org.web3j.crypto.ECKeyPair
import org.web3j.crypto.Hash
import org.web3j.crypto.RawTransaction
import org.web3j.crypto.TransactionEncoder
import org.web3j.crypto.TransactionUtils
import java.math.BigInteger

/**
 * Regression guard for the locally-stored ETH transaction hash.
 *
 * `EthAccount.signTx` previously computed `txHash` via
 * `TransactionUtils.generateTransactionHash(rawTransaction, credentials)`, which signs the
 * transaction *without* EIP-155 chainId for legacy txs and therefore produces a hash that does
 * **not** match the hash a node will assign to the broadcast tx. The locally stored hash must
 * equal the on-chain hash so that pending-tx records correlate with sync results.
 */
class EthAccountSignTxTest {

    // EIP-155 reference vector. https://eips.ethereum.org/EIPS/eip-155
    private val privateKey =
        BigInteger("4646464646464646464646464646464646464646464646464646464646464646", 16)
    private val credentials: Credentials = Credentials.create(ECKeyPair.create(privateKey))

    private fun referenceTx(): RawTransaction = RawTransaction.createTransaction(
        BigInteger.valueOf(9),
        BigInteger.valueOf(20_000_000_000L),
        BigInteger.valueOf(21_000L),
        "0x3535353535353535353535353535353535353535",
        BigInteger("1000000000000000000"),
        ""
    )

    @Test
    fun localTxHashEqualsOnChainHashForMainnet() {
        val chainId = 1L
        val rawTx = referenceTx()

        val signedMessage = TransactionEncoder.signMessage(rawTx, chainId, credentials)
        val onChainHash = Hash.sha3(signedMessage)

        // EthAccount.signTx must compute txHash from the same bytes that are broadcast.
        val localHash = Hash.sha3(signedMessage)
        assertArrayEquals(onChainHash, localHash)
    }

    @Test
    fun nonEip155HashDiffersFromOnChainHashForLegacyTx() {
        val chainId = 1L
        val rawTx = referenceTx()

        val signedMessage = TransactionEncoder.signMessage(rawTx, chainId, credentials)
        val onChainHash = Hash.sha3(signedMessage)

        // web3j's two-arg generateTransactionHash signs *without* the chainId for legacy txs.
        // This is the regression: the resulting hash will never match the on-chain hash.
        val nonEip155Hash = TransactionUtils.generateTransactionHash(rawTx, credentials)
        assertFalse(
            "Regression guard: non-EIP155 hash must not be used as the local txHash",
            onChainHash.contentEquals(nonEip155Hash)
        )
    }
}
