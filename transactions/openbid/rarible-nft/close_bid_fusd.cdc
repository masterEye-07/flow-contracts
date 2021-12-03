import FungibleToken from "../../../../../flow-contracts/cadence/contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../../../../../flow-contracts/cadence/contracts/core/NonFungibleToken.cdc"
import RaribleOpenBid from "../../../../../flow-contracts/cadence/contracts/RaribleOpenBid.cdc"
import FUSD from "../../../../../flow-contracts/cadence/contracts/core/FUSD.cdc"
import RaribleNFT from "../../../../../flow-contracts/cadence/contracts/RaribleNFT.cdc"

transaction(bidId: UInt64, openBidAddress: Address) {
    let openBid: &RaribleOpenBid.OpenBid{RaribleOpenBid.OpenBidPublic}
    let bid: &RaribleOpenBid.Bid{RaribleOpenBid.BidPublic}
    let nft: @NonFungibleToken.NFT
    let mainVault: &{FungibleToken.Receiver}

    prepare(account: AuthAccount) {
        self.openBid = getAccount(openBidAddress)
            .getCapability(RaribleOpenBid.OpenBidPublicPath)!
            .borrow<&RaribleOpenBid.OpenBid{RaribleOpenBid.OpenBidPublic}>()
            ?? panic("Could not borrow OpenBid from provided address")

        self.bid = self.openBid.borrowBid(bidId: bidId) 
            ?? panic("No Offer with that ID in OpenBid")

        let nftId = self.bid.getDetails().nftId
        let nftCollection = account.borrow<&RaribleNFT.Collection>(from: RaribleNFT.collectionStoragePath) 
            ?? panic("Cannot borrow NFT collection receiver from account")
        self.nft <- nftCollection.withdraw(withdrawID: nftId)

        self.mainVault = account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from account storage")
    }

    execute {
        let vault <- self.bid.purchase(item: <-self.nft)!
        self.mainVault.deposit(from: <-vault)
        self.openBid.cleanup(bidId: bidId)
    }
}