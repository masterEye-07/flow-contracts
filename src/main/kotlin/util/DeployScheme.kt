package util

import com.nftco.flow.sdk.FlowAccessApi
import com.nftco.flow.sdk.FlowId
import com.nftco.flow.sdk.FlowTransactionResult

class DeployScheme(val api: FlowAccessApi, val contracts: Contracts, val accounts: Accounts) {
    fun deploy() {
        println("Deploy contracts:")
        contracts.contractsForDeploy().map { contract ->
            val account = accounts.byAddress[contract.address]!!
            deployContract(account, contract.name, contract.source)
        }
    }

    private fun deployContract(
        account: Account,
        contractName: String,
        contractSource: String,
    ): Pair<FlowId, FlowTransactionResult> {
        val source = SourceLoader.fromResource(
            if (contractName in account.flow.contracts.keys) "contract_update.cdc" else "contract_add.cdc"
        )
        return api.tx(account, source) {
            arg { string(contractName) }
            arg { byteArray(contractSource.toByteArray()) }
        }.traceTxResult("deploy:$contractName")
    }
}
