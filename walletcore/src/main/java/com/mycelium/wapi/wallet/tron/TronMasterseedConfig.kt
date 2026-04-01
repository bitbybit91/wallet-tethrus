package com.mycelium.wapi.wallet.tron

import com.mycelium.wapi.wallet.manager.Config

class TronMasterseedConfig : Config

class TronAddressConfig @JvmOverloads constructor(val address: TronAddress, label: String = "") : Config
