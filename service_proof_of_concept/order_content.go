package main

import (
	"encoding/json"
	"fmt"
)

type Products map[string]uint64

// An example of what an RPC_ORDER_CONTENT looks like is provided at the end of this file.
type OrderContent struct {
	OnChainProducts           Products `json:"onP,omitempty"`
	OnChainInventoryProducts  Products `json:"onInvP,omitempty"`
	OffChainInventoryProducts Products `json:"offInvP,omitempty"`
	Message                   string   `json:"m,omitempty"`
}

func DeserializeOrderContent(contentJSON string) (o OrderContent, err error) {
	err = json.Unmarshal([]byte(contentJSON), &o)
	if err != nil {
		err = fmt.Errorf("error unmarshalling json string into struct: %v", err)
	}
	return
}

func (o OrderContent) Serialize() (contentJSON string, err error) {
	var contentBytes []byte
	contentBytes, err = json.Marshal(o)
	if err != nil {
		err = fmt.Errorf("error marshalling struct to json string: %v", err)
	} else {
		contentJSON = string(contentBytes)
	}
	return
}

/*
Example of RPC_ORDER_CONTENT:
'{
    "onP":
    {
        "id": uint64_amount,
        "id": uint64_amount,
        ...
    },
    "onInvP"
    {
        "id": uint64_amount,
        "id": uint64_amount,
        ...
    },
    "offInvP"
    {
        "id": uint64_amount,
        "id": uint64_amount,
        ...
    },
    "m": "order message string foo bar"
}'

LEGEND:
	"onP" = ON_CHAIN_PRODUCTS = On-chain Products: refers to the products vendors add to an SC using the "AddProduct" function.
	"onInvP" = ON_CHAIN_INVENTORY_PRODUCTS = On-chain Inventory Products: refers to the products vendors list on an SC, as a JSON string, using the "SetOnChainJSONInventory" function.
	"offInvP" = OFF_CHAIN_INVENTORY_PRODUCTS = Off-chain Inventory Products: refers to the products vendors list outside of an SC, on a remote JSON file, that is linked to the SC using the "RegisterAsVendor" or "EditVendorInfo" functions.
	"m" = ORDER_MESSAGE = Order message: refers to an additional message the buyer wants to include in the order for the seller to see. Might be a physical address, for example, or any other kind of note.
*/
