# Letter of credit

## Main flow
1. Deploy a contract, define buyer and seller in the constructor
2. Create a bargain. Bargain could be created only if contract state is **ZS** or **FINISHED**. Pay attention to ```bargainDeadline``` variable: its main purpose is to defend buyer and seller from "off-line vulnerability" (bargain subjects
should be protected from frozen states and "no respond" from the other side of a bargain). Each action of buyer/seller requires state change with an explicit call to ```pushStateForwardTo```.
3. Once a bargain created and contract state is set to **INIT**, buyer should consider that seller could be trusted, he has a wanted product/service. When it's done, buyer changes state to **VALIDATED**. If doubts about seller occure, buyer can call ```cancelBargainBuyer``` and get his ether back. 
4. **VALIDATED** state is a signal for seller to begin shipping actions. Once seller shipped goods, he changes state to **SENT**. 
If he does not change state to **SENT** and ```bargainDeadline``` passes, buyer will consider that as "no-respond". In order to protect his funds, he can cancel bargain.
5. Unfortunately it's impossible to make absolutely trustless letter of credit, without involving third party. A need for a third party here is to validate that goods were shipped and received. But this "arbitier" principe widens attack opportunities. So the main "trust" point in this contract is a state between **VALIDATED** and **SENT**, because it requires a lot of off-chain actions, that can't be digitalised with smart - contracts that easily.
6. If ```bargainDeadline``` passes when state of the contract is **SENT**, seller can protect himself with ```cancelBargainSeller``` function call. It will charge 30% of bargain to seller. The rest is transfered to buyer (LOL: seller pays gas for a transaction that transfers ether to the "off-line" buyer, it would be better to change that). Logic shows an importance of proper ```bargainDeadline``` definition. 
7. Buyer accepts or declines shipped goods and changes state to **ACCEPT**/**DECLINED** respectively.
8. The final **FINISHED** state is met when call to ```transferPaymentsToParties``` is done. If bargain was declined, buyer still has to pay 15% of ```bargainSum``` as a compensation.
