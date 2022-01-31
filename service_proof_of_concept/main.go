package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/ybbus/jsonrpc"
)

var rpcClient jsonrpc.RPCClient

func main() {
	rpcAddress := "127.0.0.1:40403"
	rpcEndpoint := fmt.Sprintf("http://%s/json_rpc", rpcAddress)
	rpcClient = jsonrpc.NewClientWithOpts(rpcEndpoint, &jsonrpc.RPCClientOpts{
		HTTPClient: &http.Client{Timeout: time.Second * 10},
	})

	// BUYER ORDER TEST
	/*o := OrderContent{
		OnChainProducts: Products{
			"123":  10,
			"156":  2,
			"1231": 10,
			"1562": 2,
			"1233": 10,
			"1564": 2,
		},
		OnChainInventoryProducts: Products{
			"8342032":    1234,
			"932108312":  929394,
			"83420324":   1234,
			"9321083125": 929394,
		},
		OffChainInventoryProducts: Products{
			"2891348": 91319,
			"9393":    12932032,
		},
		Message: "Ehi bruuuh",
	}
	content, err := o.Serialize()
	if err != nil {
		log.Fatalf("Error serializing order: %v\n", err)
	}

	orderPayloads, err := NewOrderPayloads(MARKETPLACE_DEST_PORT, "b2e6122e52850a79fa997023ee713d47882002b94b99c4da4a385ec374ec27ba", getRandomOrderID(), content)
	if err != nil {
		log.Fatalf("Error creating new direct message payload: %v\n", err)
	}

	t := orderPayloads.BuildTransferParams("deto1qyre7td6x9r88y4cavdgpv6k7lvx6j39lfsx420hpvh3ydpcrtxrxqg8v8e3z", 200000, DEFAULT_RING_SIZE)
	fmt.Printf("Order Parts Count: %d\n", len(orderPayloads))
	fmt.Printf("Order Transfer Params: %+v\n", t)

	res, err := sendTransaction(t)
	if err != nil {
		fmt.Println("Error sending transaction", err)
	}

	fmt.Printf("\nTX Result: %+v\n", res)*/

	// MESSAGE TEST
	/*dmPayload, dmFreeBytes, err := NewDirectMessagePayload(DIRECTMESSAGE_DEST_PORT, "", getRandomOrderID())
	if err != nil {
		log.Fatalf("Error creating new direct message payload: %v\n", err)
	}
	fmt.Printf("DM Free Bytes: %d\n", dmFreeBytes)

	dmPayload[1].Value = "Hello, here is a message for you!" // 1 = RPC_MKT_DM (it's the actual message)

	t := dmPayload.BuildTransferParams("deto1qyre7td6x9r88y4cavdgpv6k7lvx6j39lfsx420hpvh3ydpcrtxrxqg8v8e3z", 1, DEFAULT_RING_SIZE)
	fmt.Printf("DM Transfer Params: %+v\n", t)

	res, err := sendTransaction(t)
	if err != nil {
		fmt.Println("Error sending transaction", err)
	}

	fmt.Printf("\nTX Result: %+v\n", res)*/

	// VENDOR TXS PROCESSING TEST
	/*go processDirectMessages(DIRECTMESSAGE_DEST_PORT)
	go processOrders(MARKETPLACE_DEST_PORT)*/

	// DERO RPC TESTS
	/*addr, err := getAddress()
	fmt.Println(addr, err)

	h, err := getHeight()
	fmt.Println(h, err)*/

}
