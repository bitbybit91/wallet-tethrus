package com.tethrus.wallet.tron

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import java.math.BigInteger
import java.util.concurrent.TimeUnit

// ---------------------------------------------------------------------------
// Retrofit service interface
// ---------------------------------------------------------------------------

private interface TronGridService {

    /** Returns the full account object for [address]. */
    @GET("v1/accounts/{address}")
    suspend fun getAccount(@Path("address") address: String): Response<AccountResponse>

    /**
     * Returns TRC-20 token balances held by [address] for the contract at [contractAddress].
     * The optional [limit] caps results when [contractAddress] is omitted.
     */
    @GET("v1/accounts/{address}/tokens")
    suspend fun getTrc20Tokens(
        @Path("address") address: String,
        @Query("contract_address") contractAddress: String,
        @Query("token_id") tokenId: String = "",
        @Query("limit") limit: Int = 1
    ): Response<TokenBalanceResponse>

    /** Broadcasts a pre-signed raw transaction hex string to the network. */
    @POST("wallet/broadcasthex")
    suspend fun broadcastTransactionHex(@Body body: BroadcastHexBody): Response<BroadcastResult>
}

// ---------------------------------------------------------------------------
// DTOs  (internal — field names must match the TronGrid JSON API exactly)
// ---------------------------------------------------------------------------

internal data class AccountResponse(
    val data: List<AccountData>?,
    val success: Boolean?
)

internal data class AccountData(
    val address: String?,
    val balance: Long?,         // TRX balance in SUN
    val bandwidth: BandwidthInfo?,
    val NetLimit: Long?
)

internal data class BandwidthInfo(
    val freeNetLimit: Long?,
    val NetLimit: Long?,
    val EnergyLimit: Long?
)

internal data class TokenBalanceResponse(
    val data: List<TokenData>?,
    val success: Boolean?
)

internal data class TokenData(
    val token_id: String?,
    val balance: String?,       // raw integer as string
    val token_abbr: String?,
    val token_name: String?,
    val token_decimal: Int?
)

internal data class BroadcastHexBody(val transaction: String)

internal data class BroadcastResult(
    val result: Boolean?,
    val txid: String?,
    val message: String?
)

// ---------------------------------------------------------------------------
// Public result types
// ---------------------------------------------------------------------------

/** Result of fetching a TRON account from TronGrid. */
data class TronAccountResult(
    val address: String,
    val trxBalanceSun: BigInteger,
    val bandwidth: Long,
    val energy: Long
)

/** Result of fetching a single TRC-20 token balance. */
data class Trc20BalanceResult(
    val contractAddress: String,
    val rawBalance: BigInteger
)

/** Result of broadcasting a signed transaction. */
data class BroadcastTxResult(
    val success: Boolean,
    val txId: String?,
    val message: String?
)

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

/**
 * Retrofit/OkHttp-backed client for the TronGrid v1 REST API.
 *
 * The base URL is supplied at construction time and should match the
 * `BuildConfig.TRON_GRID_URL` constant injected by the relevant product flavour.
 *
 * Example instantiation from an Android module:
 * ```kotlin
 * val client = TronGridApiClient(BuildConfig.TRON_GRID_URL, debug = BuildConfig.DEBUG)
 * ```
 *
 * @param baseUrl  TronGrid base URL, e.g. `"https://api.trongrid.io"`.
 * @param apiKey   Optional TronGrid API key (x-api-key header).  When blank, the
 *                 header is omitted and the anonymous rate-limit applies.
 * @param debug    When `true`, an [HttpLoggingInterceptor] at BODY level is added.
 * @param timeoutSeconds  Connect / read / write timeout in seconds (default 30).
 */
class TronGridApiClient(
    baseUrl: String,
    private val apiKey: String = "",
    debug: Boolean = false,
    timeoutSeconds: Long = 30L
) {
    private val service: TronGridService

    init {
        val logging = HttpLoggingInterceptor().apply {
            level = if (debug) HttpLoggingInterceptor.Level.BODY
            else HttpLoggingInterceptor.Level.NONE
        }

        val http = OkHttpClient.Builder()
            .connectTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .readTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .writeTimeout(timeoutSeconds, TimeUnit.SECONDS)
            .addInterceptor(logging)
            .apply {
                if (apiKey.isNotBlank()) {
                    addInterceptor { chain ->
                        val req = chain.request().newBuilder()
                            .addHeader("x-api-key", apiKey)
                            .build()
                        chain.proceed(req)
                    }
                }
            }
            .build()

        val normalizedBase = if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"

        service = Retrofit.Builder()
            .baseUrl(normalizedBase)
            .client(http)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TronGridService::class.java)
    }

    // -----------------------------------------------------------------------
    // Public API
    // -----------------------------------------------------------------------

    /**
     * Fetches the on-chain account details for [address].
     *
     * @throws TronApiException when the server returns an error or the body is missing.
     */
    suspend fun getAccount(address: String): TronAccountResult {
        val response = service.getAccount(address)
        if (!response.isSuccessful) {
            throw TronApiException("getAccount failed: HTTP ${response.code()} ${response.message()}")
        }
        val body = response.body()
            ?: throw TronApiException("getAccount: empty response body for $address")

        val data = body.data?.firstOrNull()
        return TronAccountResult(
            address = address,
            trxBalanceSun = BigInteger.valueOf(data?.balance ?: 0L),
            bandwidth = data?.bandwidth?.freeNetLimit ?: 0L,
            energy = data?.bandwidth?.EnergyLimit ?: 0L
        )
    }

    /**
     * Fetches the TRC-20 token balance for [address] from the contract at [contractAddress].
     *
     * @throws TronApiException on HTTP errors or missing data.
     */
    suspend fun getTrc20Balance(address: String, contractAddress: String): Trc20BalanceResult {
        val response = service.getTrc20Tokens(address, contractAddress)
        if (!response.isSuccessful) {
            throw TronApiException(
                "getTrc20Balance failed: HTTP ${response.code()} ${response.message()}"
            )
        }
        val body = response.body()
            ?: throw TronApiException("getTrc20Balance: empty response body")

        val rawBalance = body.data
            ?.firstOrNull { it.token_id == contractAddress }
            ?.balance
            ?.let { runCatching { BigInteger(it) }.getOrNull() }
            ?: BigInteger.ZERO

        return Trc20BalanceResult(contractAddress = contractAddress, rawBalance = rawBalance)
    }

    /**
     * Broadcasts a pre-signed raw transaction to the network.
     *
     * @param rawHex  Hex-encoded signed transaction bytes.
     * @throws TronApiException on HTTP errors.
     */
    suspend fun broadcastTransaction(rawHex: String): BroadcastTxResult {
        val response = service.broadcastTransactionHex(BroadcastHexBody(rawHex))
        if (!response.isSuccessful) {
            throw TronApiException(
                "broadcastTransaction failed: HTTP ${response.code()} ${response.message()}"
            )
        }
        val body = response.body()
        return BroadcastTxResult(
            success = body?.result ?: false,
            txId = body?.txid,
            message = body?.message
        )
    }
}

/** Thrown when a TronGrid API call fails. */
class TronApiException(message: String, cause: Throwable? = null) : Exception(message, cause)
