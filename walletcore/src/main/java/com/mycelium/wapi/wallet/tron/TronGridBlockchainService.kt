package com.mycelium.wapi.wallet.tron

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonParser
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.logging.Level
import java.util.logging.Logger

/**
 * Implementation of TronBlockchainService using the TronGrid REST API.
 *
 * TronGrid provides a fully compatible set of Tron Full Node APIs:
 * - Account queries (balance, resources)
 * - Transaction broadcasting
 * - TRC20 token balance and transfer queries
 * - Block information
 *
 * @param apiBaseUrl The base URL for the TronGrid API (e.g., "https://api.trongrid.io")
 * @param apiKey Optional TronGrid API key for higher rate limits
 */
class TronGridBlockchainService(
    private val apiBaseUrl: String = TronConstants.MAINNET_API_URL,
    private val apiKey: String? = TronConstants.TRONGRID_API_KEY
) : TronBlockchainService {

    private val logger = Logger.getLogger(TronGridBlockchainService::class.java.simpleName)
    private val gson: Gson = GsonBuilder().create()
    @Suppress("DEPRECATION")
    private val jsonParser = JsonParser()

    override fun getBalance(address: String): Long {
        return try {
            val response = httpPost(
                "$apiBaseUrl/wallet/getaccount",
                """{"address":"$address","visible":true}"""
            )
            val json = jsonParser.parse(response).asJsonObject
            json.get("balance")?.asLong ?: 0L
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get TRX balance for $address", e)
            0L
        }
    }

    override fun getTrc20Balance(address: String, contractAddress: String): Long {
        return try {
            // Use TronGrid v1 API for TRC20 balance
            val response = httpGet(
                "$apiBaseUrl/v1/accounts/$address"
            )
            val json = jsonParser.parse(response).asJsonObject
            val data = json.getAsJsonArray("data")
            if (data != null && data.size() > 0) {
                val account = data[0].asJsonObject
                val trc20Array = account.getAsJsonArray("trc20")
                if (trc20Array != null) {
                    for (element in trc20Array) {
                        val tokenObj = element.asJsonObject
                        if (tokenObj.has(contractAddress)) {
                            return tokenObj.get(contractAddress).asLong
                        }
                    }
                }
            }
            0L
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get TRC20 balance for $address", e)
            0L
        }
    }

    override fun getTransactions(address: String, limit: Int, fingerprint: String?): List<TronTransactionInfo> {
        return try {
            var url = "$apiBaseUrl/v1/accounts/$address/transactions?limit=$limit"
            if (fingerprint != null) {
                url += "&fingerprint=$fingerprint"
            }
            val response = httpGet(url)
            val json = jsonParser.parse(response).asJsonObject
            val data = json.getAsJsonArray("data") ?: return emptyList()
            data.map { element ->
                val tx = element.asJsonObject
                val rawData = tx.getAsJsonObject("raw_data")
                val contract = rawData?.getAsJsonArray("contract")?.get(0)?.asJsonObject
                val paramValue = contract?.getAsJsonObject("parameter")?.getAsJsonObject("value")
                TronTransactionInfo(
                    txId = tx.get("txID")?.asString ?: "",
                    blockNumber = tx.get("blockNumber")?.asLong ?: 0L,
                    timestamp = rawData?.get("timestamp")?.asLong ?: 0L,
                    from = paramValue?.get("owner_address")?.asString ?: "",
                    to = paramValue?.get("to_address")?.asString ?: "",
                    amount = paramValue?.get("amount")?.asLong ?: 0L,
                    confirmed = tx.getAsJsonArray("ret")?.get(0)?.asJsonObject
                        ?.get("contractRet")?.asString == "SUCCESS"
                )
            }
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get transactions for $address", e)
            emptyList()
        }
    }

    override fun getTrc20Transfers(
        address: String,
        contractAddress: String,
        limit: Int,
        fingerprint: String?
    ): List<TronTrc20TransferInfo> {
        return try {
            var url = "$apiBaseUrl/v1/accounts/$address/transactions/trc20?limit=$limit&contract_address=$contractAddress"
            if (fingerprint != null) {
                url += "&fingerprint=$fingerprint"
            }
            val response = httpGet(url)
            val json = jsonParser.parse(response).asJsonObject
            val data = json.getAsJsonArray("data") ?: return emptyList()
            data.map { element ->
                val tx = element.asJsonObject
                val tokenInfo = tx.getAsJsonObject("token_info")
                TronTrc20TransferInfo(
                    txId = tx.get("transaction_id")?.asString ?: "",
                    blockNumber = tx.get("block_timestamp")?.asLong?.div(1000) ?: 0L,
                    timestamp = tx.get("block_timestamp")?.asLong ?: 0L,
                    from = tx.get("from")?.asString ?: "",
                    to = tx.get("to")?.asString ?: "",
                    amount = tx.get("value")?.asLong ?: 0L,
                    contractAddress = contractAddress,
                    tokenSymbol = tokenInfo?.get("symbol")?.asString ?: "USDT",
                    tokenDecimals = tokenInfo?.get("decimals")?.asInt ?: 6,
                    confirmed = true
                )
            }
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get TRC20 transfers for $address", e)
            emptyList()
        }
    }

    override fun broadcastTransaction(signedTransaction: String): TronBroadcastResult {
        return try {
            val response = httpPost(
                "$apiBaseUrl/wallet/broadcasttransaction",
                signedTransaction
            )
            val json = jsonParser.parse(response).asJsonObject
            val result = json.get("result")?.asBoolean ?: false
            TronBroadcastResult(
                success = result,
                txId = json.get("txid")?.asString,
                errorMessage = if (!result) json.get("message")?.asString else null
            )
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to broadcast transaction", e)
            TronBroadcastResult(false, null, e.localizedMessage)
        }
    }

    override fun getCurrentBlockNumber(): Long {
        return try {
            val response = httpPost(
                "$apiBaseUrl/wallet/getnowblock",
                "{}"
            )
            val json = jsonParser.parse(response).asJsonObject
            val blockHeader = json.getAsJsonObject("block_header")
                ?.getAsJsonObject("raw_data")
            blockHeader?.get("number")?.asLong ?: 0L
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get current block number", e)
            0L
        }
    }

    override fun getAccountResources(address: String): TronAccountResources {
        return try {
            val response = httpPost(
                "$apiBaseUrl/wallet/getaccountresource",
                """{"address":"$address","visible":true}"""
            )
            val json = jsonParser.parse(response).asJsonObject
            val bandwidth = (json.get("freeNetLimit")?.asLong ?: 0L) -
                    (json.get("freeNetUsed")?.asLong ?: 0L)
            val energy = (json.get("EnergyLimit")?.asLong ?: 0L) -
                    (json.get("EnergyUsed")?.asLong ?: 0L)
            TronAccountResources(
                bandwidth = bandwidth.coerceAtLeast(0),
                energy = energy.coerceAtLeast(0),
                trxBalance = getBalance(address)
            )
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to get account resources for $address", e)
            TronAccountResources(0, 0, 0)
        }
    }

    override fun estimateEnergy(
        ownerAddress: String,
        contractAddress: String,
        functionSelector: String,
        parameter: String
    ): Long {
        return try {
            val response = httpPost(
                "$apiBaseUrl/wallet/triggerconstantcontract",
                """{
                    "owner_address":"$ownerAddress",
                    "contract_address":"$contractAddress",
                    "function_selector":"$functionSelector",
                    "parameter":"$parameter",
                    "visible":true
                }"""
            )
            val json = jsonParser.parse(response).asJsonObject
            json.get("energy_used")?.asLong ?: 65000L // Default TRC20 transfer energy
        } catch (e: Exception) {
            logger.log(Level.WARNING, "Failed to estimate energy", e)
            65000L // Default estimate for TRC20 transfer
        }
    }

    @Throws(IOException::class)
    private fun httpPost(urlString: String, body: String): String {
        val url = URL(urlString)
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            apiKey?.let {
                connection.setRequestProperty("TRON-PRO-API-KEY", it)
            }
            connection.doOutput = true
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            connection.outputStream.use { os ->
                os.write(body.toByteArray())
            }
            val responseCode = connection.responseCode
            if (responseCode != 200) {
                throw IOException("HTTP $responseCode from $urlString")
            }
            return connection.inputStream.bufferedReader().readText()
        } finally {
            connection.disconnect()
        }
    }

    @Throws(IOException::class)
    private fun httpGet(urlString: String): String {
        val url = URL(urlString)
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept", "application/json")
            apiKey?.let {
                connection.setRequestProperty("TRON-PRO-API-KEY", it)
            }
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            val responseCode = connection.responseCode
            if (responseCode != 200) {
                throw IOException("HTTP $responseCode from $urlString")
            }
            return connection.inputStream.bufferedReader().readText()
        } finally {
            connection.disconnect()
        }
    }
}
