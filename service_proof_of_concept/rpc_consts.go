package main

import "github.com/deroproject/derohe/rpc"

const (
	MARKETPLACE_DEST_PORT  = 6758
	PERSONALSHOP_DEST_PORT = 7658
)

const (
	// RPC_ORDER_ID is of type Uint64.
	// It needs to be unique on the buyer part. That means the buyer CAN'T send orders with the same ID to the same vendor, whereas the vendor CAN receive orders with the same ID, as long as they come from different buyers.
	// It could theoretically be any number the buyer hans't used already to make an order. Therefore, it's number generated randomly.
	RPC_ORDER_ID = "ID"
	// RPC_ORDER_PART is of type Uint64.
	// Since the content of an order may be so long it takes more than a TX to fit, this field is used to tag the parts of the TXs so that the content can be rebuilt properly on the vendor side.
	RPC_ORDER_PART = "P"
	// RPC_ORDER_FINAL_PART is of type Uint64.
	// It replaces RPC_ORDER_PART in the TX that contains the last part of the order. This signals how many TXs make up an order, so that its content can be rebuilt properly on the vendor side.
	// Therefore, an order that requires just one TX will have the "F" field instead of the "P" field.
	RPC_ORDER_FINAL_PART = "F"
	// RPC_ORDER_CONTENT is of type String.
	// The const rpc.RPC_COMMENT is reused since it shares the same value "C".
	// This field contains the stringified JSON content of the order, or a part of it, if the order requires more than one TX.
	// An example of what an RPC_ORDER_CONTENT looks like is provided in the order_content.go file.
	RPC_ORDER_CONTENT = rpc.RPC_COMMENT // = "C"
	// RPC_MTK_SCID is of type String.
	// This field contains the SCID of the marketplace/personal shop the vendor is on.
	// It is only sent in part 1 of an order.
	RPC_MKT_SCID = "MKT_SCID"

	// RPC_VALUE_TRANSFER. Value (amount due for the order) is transfered only in the final part.
	// However, on the seller side part of the service, values from every TX that makes up the order should be summed.
)

const DIRECTMESSAGE_DEST_PORT = 6743

const (
	// RPC_MKT_DM is of type String.
	// It's used for exchanging messages between buyers and vendors.
	// Value can be transfered alongside it in order for buyers to send more funds or for vendors to refund.
	RPC_MKT_DM = "MKT_DM"
	// RPC_ORDER_ID_REF is of type Uint64.
	// It's an OPTIONAL param that allows the sender to communicate the receiver that the direct message is in reference of this order ID.
	// Can be useful to the seller of a digital product to send the product key to buyer.
	RPC_ORDER_ID_REF = "ID_REF"
)
