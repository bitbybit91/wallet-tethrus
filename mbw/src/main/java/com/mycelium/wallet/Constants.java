/*
 * Copyright 2013, 2014 Megion Research and Development GmbH
 *
 * Licensed under the Microsoft Reference Source License (MS-RSL)
 *
 * This license governs use of the accompanying software. If you use the software, you accept this license.
 * If you do not accept the license, do not use the software.
 *
 * 1. Definitions
 * The terms "reproduce," "reproduction," and "distribution" have the same meaning here as under U.S. copyright law.
 * "You" means the licensee of the software.
 * "Your company" means the company you worked for when you downloaded the software.
 * "Reference use" means use of the software within your company as a reference, in read only form, for the sole purposes
 * of debugging your products, maintaining your products, or enhancing the interoperability of your products with the
 * software, and specifically excludes the right to distribute the software outside of your company.
 * "Licensed patents" means any Licensor patent claims which read directly on the software as distributed by the Licensor
 * under this license.
 *
 * 2. Grant of Rights
 * (A) Copyright Grant- Subject to the terms of this license, the Licensor grants you a non-transferable, non-exclusive,
 * worldwide, royalty-free copyright license to reproduce the software for reference use.
 * (B) Patent Grant- Subject to the terms of this license, the Licensor grants you a non-transferable, non-exclusive,
 * worldwide, royalty-free patent license under licensed patents for reference use.
 *
 * 3. Limitations
 * (A) No Trademark License- This license does not grant you any rights to use the Licensor’s name, logo, or trademarks.
 * (B) If you begin patent litigation against the Licensor over patents that you think may apply to the software
 * (including a cross-claim or counterclaim in a lawsuit), your license to the software ends automatically.
 * (C) The software is licensed "as-is." You bear the risk of using it. The Licensor gives no express warranties,
 * guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot
 * change. To the extent permitted under your local laws, the Licensor excludes the implied warranties of merchantability,
 * fitness for a particular purpose and non-infringement.
 */

package com.mycelium.wallet;

import com.mycelium.wallet.GpsLocationFetcher.GpsLocationEx;

public interface Constants {
   // USDT-TRC20 uses 6 decimal places (1 USDT = 1,000,000 micro-units)
   long ONE_USDT_MICRO = 1;
   long ONE_USDT_MILLI = 1000 * ONE_USDT_MICRO;
   long ONE_USDT_IN_MICRO = 1000000;

   // TRX uses 6 decimal places (1 TRX = 1,000,000 SUN)
   long ONE_TRX_IN_SUN = 1000000;

   // Legacy constants kept for backward compatibility with existing code
   long ONE_uBTC_IN_SATOSHIS = 100;
   long ONE_mBTC_IN_SATOSHIS = 1000 * ONE_uBTC_IN_SATOSHIS;
   long ONE_BTC_IN_SATOSHIS  = 1000 * ONE_mBTC_IN_SATOSHIS;

   long MS_PR_SECOND = 1000L;
   long MS_PR_MINUTE = MS_PR_SECOND * 60;
   long MS_PR_HOUR = MS_PR_MINUTE * 60;
   long MS_PR_DAY = MS_PR_HOUR * 24;

   int SHORT_HTTP_TIMEOUT_MS = 4000;

   // Tron network parameters
   int TRON_BLOCK_TIME_IN_SECONDS = 3;
   int TRON_BLOCKS_PER_DAY = (24 * 60 * 60) / TRON_BLOCK_TIME_IN_SECONDS;

   // USDT TRC20 contract addresses
   String USDT_TRC20_CONTRACT_MAINNET = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
   String USDT_TRC20_CONTRACT_TESTNET = "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf";

   // TronGrid API endpoints
   String TRONGRID_MAINNET_API = "https://api.trongrid.io";
   String TRONGRID_NILE_TESTNET_API = "https://nile.trongrid.io";
   String TRONGRID_SHASTA_TESTNET_API = "https://api.shasta.trongrid.io";

   // Tronscan block explorer
   String TRONSCAN_MAINNET_URL = "https://tronscan.org";
   String TRONSCAN_TESTNET_URL = "https://nile.tronscan.org";

   /**
    * Settings and their default values
    */
   String SETTINGS_NAME = "settings";
   String EXCHANGE_DATA = "wapi_exchange_rates";
   String PIN_SETTING = "PIN";
   String PIN_SETTING_RESETTABLE = "PinResettable";
   String RANDOMIZE_PIN = "randomizePin";
   String PIN_SETTING_REQUIRED_ON_STARTUP = "PinOnStartup";
   String FINGERPRINT = "fingerprint";
   String TWO_FACTOR = "twoFactor";
   String PROXY_SETTING = "proxy";
   String TOTAL_FIAT_CURRENCY_SETTING = "TotalFiatCurrency";
   // last selected fiat currencies, used as alternative amount
   String FIAT_CURRENCIES_SETTING = "FiatCurrencies";
   // last selected currencies (could be fiat also), used as representation
   String CURRENT_CURRENCIES_SETTING = "CurrentCurrencies";
   String SELECTED_CURRENCIES = "selectedFiatCurrencies";
   String DEFAULT_CURRENCY = "USD";
   String DEFAULT_EXCHANGE = "Binance";
   String DENOMINATION_SETTING = "Denomination";
   String EXCHANGE_RATE_SETTING = "currentRateName";
   String MINER_FEE_SETTING = "MinerFeeEstimationSetting";
   String KEY_MANAGEMENT_LOCKED_SETTING = "KeyManagementLocked";
   String TETHRUS_WALLET_HELP_URL = "https://tron.network/wallet/help";
   String PLAYSTORE_BASE_URL = "https://play.google.com/store/apps/details?id=";
   String DIRECT_APK_URL = "https://wallet.tethrus.com";
   String LANGUAGE_SETTING = "user_language";
   String IGNORED_VERSIONS = "ignored_versions";
   String TOR_MODE = "tor_mode";
   String BLOCK_EXPLORERS = "BlockExplorers";
   String CHANGE_ADDRESS_MODE = "change_type";
   String LAST_FIO_SENDER = "fio_sender";

   // Ledger preferences (kept for backward compatibility)
   String LEDGER_SETTINGS_NAME = "ledger_settings";
   String LEDGER_DISABLE_TEE_SETTING = "ledger_disable_tee";
   String LEDGER_UNPLUGGED_AID_SETTING = "ledger_unplugged_aid";

   String TAG = "TethrusWallet";

   // Trading platform constants (replaces Local Trader)
   String LOCAL_TRADER_SETTINGS_NAME = "trading.settings";
   String LOCAL_TRADER_ADDRESS_SETTING = "traderAddress";
   String LOCAL_TRADER_KEY_SETTING = "traderPrivateKey";
   String LOCAL_TRADER_ACCOUNT_ID_SETTING = "traderAccountId";
   String LOCAL_TRADER_NICKNAME_SETTING = "nickname";
   String LOCAL_TRADER_LAST_TRADER_SYNCHRONIZATION_SETTING = "lastTraderSync";
   String LOCAL_TRADER_LAST_TRADER_NOTIFICATION_SETTING = "lastTraderNotification";
   String LOCAL_TRADER_LOCATION_NAME_SETTING = "locationName";
   String LOCAL_TRADER_LOCATION_COUNTRY_CODE_SETTING = "locationCountryCode";
   String LOCAL_TRADER_LATITUDE_SETTING = "latitude";
   String LOCAL_TRADER_LONGITUDE_SETTING = "longitude";
   GpsLocationEx LOCAL_TRADER_DEFAULT_LOCATION = new GpsLocationEx(48.2162845, 16.2484715, "Penzing, Vienna", "AT");
   String LT_DISABLED = "isLocalTraderDisabled";
   String LT_ENABLED = "isLocalTraderEnabled";
   String LOCAL_TRADER_PLAY_SOUND_ON_TRADE_NOTIFICATION_SETTING = "playSoundOnTradeNotification";
   String LOCAL_TRADER_USE_MILES_SETTING = "useMiles";
   String LOCAL_TRADER_GCM_SETTINGS_NAME = "localTrader.gcm.settings";
   String LOCAL_TRADER_HELP_URL = "https://tron.network/wallet/help";
   String LOCAL_TRADER_MAP_URL = "https://tronscan.org";

   String IGNORE_NEW_API = "NewApi";

   String TRANSACTION_ID_INTENT_KEY = "transaction_id";
   String TRANSACTION_FIAT_VALUE_KEY = "transaction_fiat_value";

   int BITCOIN_BLOCKS_PER_DAY = TRON_BLOCKS_PER_DAY;
   int BTC_BLOCK_TIME_IN_SECONDS = TRON_BLOCK_TIME_IN_SECONDS;

   // Minimum age of the PIN in blocks, so that we allow a second wordlist backup
   int MIN_PIN_BLOCKHEIGHT_AGE_ADDITIONAL_BACKUP = 2 * TRON_BLOCKS_PER_DAY;

   // Minimum age of the PIN in blocks, until you can reset the PIN
   int MIN_PIN_BLOCKHEIGHT_AGE_RESET_PIN = 7 * TRON_BLOCKS_PER_DAY;
   // Force user to read the warnings about additional backups
   int WAIT_SECONDS_BEFORE_ADDITIONAL_BACKUP = 60;

   String FAILED_PIN_COUNT = "failedPinCount";

   String SETTING_TOR = "useTor";
   String SETTING_DENOMINATION = "usdt_denomination";
   String SETTING_MINER_FEE = "network_fee";
   long CONFIG_UPDATE_PERIOD_MINS = 20;

   String BAD_REQUEST_HTTP_CODE = "400";
}
