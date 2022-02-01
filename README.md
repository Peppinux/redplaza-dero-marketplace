# Redplaza Dero Marketplace
Redplaza: a decentralized marketplace platform running on Dero.

# PROPOSAL

## What Redplaza is
Redplaza is an hybrid between SCs and services. It is made up of:
1. Standardized Smart Contracts for creating Marketplaces and Personal Stores.
2. Service to allow purchasing items and messaging between buyers and vendors.
The SCs are deployed on the Dero network.
The service and everything around it **run locally**. No need to connect to a website, no need for TOR. The only requirement is a Dero wallet.

## Why the name "Redplaza"?
I have no idea, it just came to me. I didn't want waste too much time finding the perfect name so if you have suggestions, you're free to leave them.

## What Redplaza isn't
**IT'S NOT A MARKETPLACE PER SE. AND I AM NOT THE OWNER OF IT.**
It is code that allows the creation of marketplaces/personal stores. Anyone can deploy a SC and be the sole owner of it, with the responsability that comes with that.

## The MARKETPLACE smart contract
It allows the owner to, guess what, create a marketplace.

### What can the owner do?
1. Open or close registrations to their platform.
2. Ban users that don't comply to the rules of the market.
3. TODO?: Set a whitelist of vendors.
4. TODO: Be in charge of escrow, when it will be developed.

### What can registered vendors do?
They can manage their inventory, and they can do it in three ways!
1. ON CHAIN: By adding the products, one by one, directly on the SC storage (AddProduct function).
2. ON CHAIN: By adding their products in bulk, using JSON stored in the SC (SetOnChainJSONInventory function)
3. OFF CHAIN: By providing a URL to a JSON file, either on a centralized website or to IPFS/something along those lines.
And they can do all of the above at the same time. A vendor can have some products on chain and others off chain.

### What can buyers do?
1. Leave reviews of vendors.
2. TODO?: Leave reviews of products.
3. TODO: Paying through escrow, which is not developed yet.

So how do buyers actually buy the items listed by a vendor? The creation of the order and the payment happens through the service protocol. Until escrow is developed, the only way to pay is to directly send the coins to the vendor.

## The PERSONAL SHOP smart contract
It's basically the same as the marketplace smart contract, but the owner and the vendor are the same person. And only that person can sell on their personal shop (pretty straight forward).

## About the Smart Contracts
If you want to understand them more deeply, check out the .bas and Schema.txt files inside their folders.

Note that they have yet to be updated to use the latest functions added by Captain (like ITOA, MAPSTORE etc.). They will be updated when we get a final release in order to allow the best code refactoring.

## The SERVICE (WIP)
As you can see, there is a folder with a proof of concept in its infancy. Some of logic is already written there, but it will need to change. Why? Because the service needs a frontend. People (buyers but also sellers) are used to do their shopping on webpages, not CLIs. That's why I feel that the best option is to use a WASM compiled version of my Golang POC, which will use WebSockets instead of RPC, is run on a React frontend and uses IndexedDB for storage/caching. All of this can still happen **locally**, but there could also exist an hosted version, perhaps on the Foundation's domain.

In order to understand how the service is going to work, I suggest to check out specifically https://github.com/Peppinux/redplaza-dero-marketplace/blob/main/service_proof_of_concept/rpc_consts.go and https://github.com/Peppinux/redplaza-dero-marketplace/blob/main/service_proof_of_concept/order_content.go 

## Limits of Redplaza
The main one is that it is very vendor-centric. Because of the how products are stored (on-chain and off-chain) which is, not on some SQL server, I see it more like a collection of sellers rather than your typical market where the products are the focus. But this limit may be overcame.
