package main

import (
	"encoding/json"
	"fmt"

	"github.com/deroproject/derohe/rpc"
	"github.com/ybbus/jsonrpc"
)

func sendTransaction(t rpc.Transfer_Params) (result rpc.Transfer_Result, err error) {
	err = rpcClient.CallFor(&result, "Transfer", t)
	if err != nil {
		err = fmt.Errorf("error calling Transfer method: %v", err)
		return
	}

	return
}

func getTransfers(t rpc.Get_Transfers_Params) (result rpc.Get_Transfers_Result, err error) {
	err = rpcClient.CallFor(&result, "GetTransfers", t)
	if err != nil {
		err = fmt.Errorf("error calling GetTransfers method: %v", err)
		return
	}

	return
}

func getHeight() (height uint64, err error) {
	request := &jsonrpc.RPCRequest{
		Method:  "GetHeight",
		JSONRPC: "2.0",
	}

	resp, err := rpcClient.CallRaw(request)
	if err != nil {
		return
	}

	h := resp.Result.(map[string]interface{})["height"].(json.Number)
	he, err := h.Int64()
	if err != nil {
		return
	}

	height = uint64(he)
	return
}

func getAddress() (address string, err error) {
	request := &jsonrpc.RPCRequest{
		Method:  "GetAddress",
		JSONRPC: "2.0",
	}

	resp, err := rpcClient.CallRaw(request)
	if err != nil {
		return
	}

	address = resp.Result.(map[string]interface{})["address"].(string)
	return
}
