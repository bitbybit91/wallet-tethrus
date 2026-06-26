package com.mycelium.wapi.wallet.eth

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.web3j.crypto.Credentials
import org.web3j.crypto.Hash
import org.web3j.crypto.RawTransaction
import org.web3j.crypto.TransactionEncoder
import org.web3j.crypto.TransactionUtils
import org.web3j.tx.ChainIdLong
import java.math.BigInteger

/**
 * Regression for the cancel/replace ETH tx commit which switched EthAccount's
 * chainId from Byte to Long but, because web3j 4.12 has no
 * `generateTransactionHash(RawTransaction, long, Credentials)` overload, the
 * call site was rewritten to drop chainId entirely:
 *
 *   txHash = TransactionUtils.generateTransactionHash(rawTransaction, credentials)
 *
 * That overload signs the tx **without** EIP-155, so the resulting hash does
 * not match the EIP-155 signed payload that gets broadcast (which is what the
 * Ethereum node returns as the canonical tx hash). The wallet stored the wrong
 * id locally; `syncTransactions()` then deletes the entry after 150s because
 * the remote tx list never contains it, hiding the user's own outbound tx.
 *
 * The correct hash is `keccak256(signedMessage)` where `signedMessage` is the
 * EIP-155 encoded payload we already produce for broadcast.
 */
class EthTransactionHashTest {

    /** Deterministic 32-byte private key — value is irrelevant beyond reproducibility. */
    private val credentials: Credentials = Credentials.create(
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
    )

    private fun sampleRawTx(): RawTransaction = RawTransaction.createTransaction(
        BigInteger.valueOf(7),
        BigInteger.valueOf(20_000_000_000L),
        BigInteger.valueOf(21_000),
        "0x3535353535353535353535353535353535353535",
        BigInteger.valueOf(1_000_000_000_000_000L),
        ""
    )

    /**
     * The legacy buggy path (`generateTransactionHash` without chainId)
     * produces a pre-EIP-155 hash that does **not** match the hash of the
     * EIP-155 signed payload we actually broadcast for any non-trivial
     * chainId. Sepolia (11155111) is the obvious offender after the
     * EthereumModule bump from Goerli (5) to ChainIdLong.SEPOLIA.
     */
    @Test
    fun noChainIdHashDoesNotMatchBroadcastHashForLongChainId() {
        val raw = sampleRawTx()
        val chainId = ChainIdLong.SEPOLIA

        val signedMessage = TransactionEncoder.signMessage(raw, chainId, credentials)
        val onChainHash = Hash.sha3(signedMessage)

        val buggyHash = TransactionUtils.generateTransactionHash(raw, credentials)

        assertNotEquals(
            "Pre-EIP-155 generateTransactionHash must not match the EIP-155 " +
                "broadcast hash; if these are ever equal the regression guard " +
                "is meaningless.",
            onChainHash.toList(),
            buggyHash.toList()
        )
    }

    /**
     * Mainnet (chainId = 1L) is the production-money path. Confirm that the
     * dropped-chainId hash diverges here too, so the local tx-id stored by
     * EthAccount.signTx is wrong on mainnet, not just on testnets.
     */
    @Test
    fun noChainIdHashDoesNotMatchBroadcastHashOnMainnet() {
        val raw = sampleRawTx()
        val chainId = ChainIdLong.MAINNET

        val signedMessage = TransactionEncoder.signMessage(raw, chainId, credentials)
        val onChainHash = Hash.sha3(signedMessage)

        val buggyHash = TransactionUtils.generateTransactionHash(raw, credentials)

        assertNotEquals(
            "Pre-EIP-155 generateTransactionHash must not match the EIP-155 " +
                "broadcast hash on mainnet.",
            onChainHash.toList(),
            buggyHash.toList()
        )
    }

    /**
     * The fix used by EthAccount.signTx — hash the signedMessage we are about
     * to broadcast — agrees with `TransactionUtils.generateTransactionHash`
     * called with the same chainId, i.e. it is the real on-chain txid.
     */
    @Test
    fun sha3OfSignedMessageEqualsCanonicalHash() {
        val raw = sampleRawTx()
        // ChainIdLong.SEPOLIA does not fit in a byte; pick a value that does
        // so we can cross-check against the byte-chainId overload, which is
        // still backed by the same signing path internally.
        val chainId: Long = 1L
        val signedMessage = TransactionEncoder.signMessage(raw, chainId, credentials)

        val fixHash = Hash.sha3(signedMessage)
        val canonicalHash =
            TransactionUtils.generateTransactionHash(raw, chainId.toByte(), credentials)

        assertEquals(
            "Hash size must be 32 bytes (keccak256)",
            32,
            fixHash.size
        )
        assertArrayEquals(
            "Hashing the EIP-155 signedMessage must match " +
                "TransactionUtils.generateTransactionHash with the same chainId.",
            canonicalHash,
            fixHash
        )
    }
}
