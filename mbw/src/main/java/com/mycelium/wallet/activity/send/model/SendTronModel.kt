package com.mycelium.wallet.activity.send.model

import android.app.Application
import android.content.Intent
import com.mycelium.wallet.MinerFee
import com.mycelium.wallet.Utils
import com.mycelium.wallet.activity.send.view.SelectableRecyclerView
import com.mycelium.wapi.wallet.FeeEstimationsGeneric
import com.mycelium.wapi.wallet.WalletAccount
import com.mycelium.wapi.wallet.coins.Value
import com.mycelium.wapi.wallet.tron.coins.TronCoin
import java.util.Date

class SendTronModel(
    application: Application,
    account: WalletAccount<*>,
    intent: Intent
) : SendCoinsModel(application, account, intent) {

    init {
        val coinType = account.coinType
        // Tron has no miner fee for simple TRX transfers (uses bandwidth)
        // TRC20 transfers consume energy which may cost TRX
        val feeValue = Value.zeroValue(coinType)
        selectedFee.value = feeValue
        feeEstimation = FeeEstimationsGeneric(
            feeValue, feeValue, feeValue, feeValue, Date().time
        )
    }

    override fun handlePaymentRequest(toSend: Value): TransactionStatus {
        return TransactionStatus.OK
    }

    override fun getFeeLvlItems(): List<FeeLvlItem> {
        return MinerFee.values().map { fee ->
            val blocks = when (fee) {
                MinerFee.LOWPRIO -> 120
                MinerFee.ECONOMIC -> 20
                MinerFee.NORMAL -> 8
                MinerFee.PRIORITY -> 2
            }
            val duration = Utils.formatBlockcountAsApproxDuration(
                mbwManager, blocks, TronCoin.BLOCK_TIME_IN_SECONDS
            )
            FeeLvlItem(fee, "~$duration", SelectableRecyclerView.SRVAdapter.VIEW_TYPE_ITEM)
        }
    }
}
