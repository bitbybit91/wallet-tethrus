Tethrus - USDT-TRC20 Trading Platform
======================================

A mobile trading platform for USDT (Tether) on the Tron (TRC20) network. Built on the robust
Mycelium wallet architecture, Tethrus provides secure USDT-TRC20 management with full support
for the Tron blockchain.

## Supported Assets

- **USDT-TRC20** (Tether USD on Tron) - Primary trading asset
- **TRX** (Tron) - Native Tron network currency for transaction fees
- **Ethereum (ETH)** and **ERC20 tokens** - Legacy support

## Network Configuration

| Network | API Endpoint | Block Explorer | USDT Contract |
|---------|-------------|----------------|---------------|
| Mainnet | `https://api.trongrid.io` | `https://tronscan.org` | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` |
| Nile Testnet | `https://nile.trongrid.io` | `https://nile.tronscan.org` | `TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf` |

Building
========

To build everything from source, simply checkout the source and build using gradle:

 * JDK 17 (required)
 * Android SDK (compileSdk 36)

#### Build commands

To get the source code, type:

    git clone https://github.com/bitbybit91/wallet-tethrus.git
    cd wallet-tethrus
    git submodule update --init --recursive

Linux/Mac type:

    ./gradlew clean test mbw::assembleProdnetRelease mbw::assembleBtctestnetRelease

Windows type:

    gradlew.bat clean test mbw::assembleProdnetRelease mbw::assembleBtctestnetRelease

 - Voila, look into `mbw/build/outputs/apk/` to see the generated apk.
   There are versions for both prodnet (mainnet) and testnet (Nile).

Configuration
=============

### TronGrid API Key

For production use, obtain a TronGrid API key from [TronGrid](https://www.trongrid.io/)
to increase rate limits. Set it in your configuration or pass it to `TronGridBlockchainService`.

### Product Flavors

| Flavor | App ID | Network |
|--------|--------|---------|
| `prodnet` | `com.tethrus.wallet` | Tron Mainnet |
| `btctestnet` | `com.tethrus.testnetwallet` | Tron Nile Testnet |
| `huaweiProdnet` | `com.tethrus.wallet.app` | Tron Mainnet (Huawei) |

### Key Derivation

Tron accounts use BIP44 path: `m/44'/195'/accountIndex'/0/0`
(coin type 195 for Tron, following SLIP-44 standard)

Features
========

 - **USDT-TRC20 Trading** - Send, receive, and manage USDT on the Tron network
 - **TRX Support** - Native TRX for network fees and transfers
 - HD enabled - manage multiple accounts and never reuse addresses (BIP32/BIP44 compatible)
 - Masterseed based - make one backup and be safe forever (BIP39)
 - 100% control over your private keys, they never leave your device unless you export them
 - No blockchain download - install and run in seconds
 - Fast connection to the Tron network through TronGrid API
 - Watch-only addresses for secure cold-storage integration
 - Secure your wallet with a PIN and fingerprint
 - QR code scanner for easy address entry
 - Multiple fiat currency display: USD, EUR, GBP, and more
 - Transaction history with detailed information
 - TRC20 token balance and transfer tracking

Architecture
============

```
wallet-tethrus/
├── mbw/                    # Main Android app module
├── walletcore/             # Core wallet business logic
│   └── tron/               # Tron/TRC20 wallet implementation
│       ├── coins/          # TronMain, TronTest coin definitions
│       ├── TronAccount.kt  # Tron account implementation
│       ├── TronModule.kt   # Tron wallet module
│       ├── TronAddress.kt  # Tron address handling
│       └── TronGridBlockchainService.kt  # TronGrid API client
├── walletmodel/            # Data models
├── bitlib/                 # Cryptographic library
├── wapi/                   # Blockchain API clients
└── gradle/                 # Build configuration
```
