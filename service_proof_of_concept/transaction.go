package main

import (
	"github.com/deroproject/derohe/rpc"
)

var DEFAULT_RING_SIZE uint64 = 8

func addTransferToTransferParams(address string, amount uint64, payload rpc.Arguments, dest *rpc.Transfer_Params) {
	if amount == 0 {
		amount = 1
	}

	transfer := rpc.Transfer{
		Destination: address,
		Amount:      amount,
		Payload_RPC: payload,
	}

	dest.Transfers = append(dest.Transfers, transfer)
}

// Credits to CheckPack func https://github.com/deroproject/derohe/blob/main/rpc/rpc.go#L162 for inspiring this function
func sizeArgs(args rpc.Arguments) (int, error) {
	packed, err := args.MarshalBinary()
	if err != nil {
		return 0, err
	}
	return len(packed), nil
}
