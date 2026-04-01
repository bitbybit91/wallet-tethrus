package com.mycelium.wapi.wallet.trc20

import com.mycelium.wapi.wallet.coins.CryptoCurrency
import com.mycelium.wapi.wallet.manager.Config

class TRC20Config constructor(val token: CryptoCurrency, val tronAccountId: java.util.UUID) : Config
