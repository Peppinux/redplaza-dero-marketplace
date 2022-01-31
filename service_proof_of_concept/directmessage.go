package main

import (
	"fmt"

	"github.com/deroproject/derohe/rpc"
	"github.com/deroproject/derohe/transaction"
)

type DirectMessagePayload rpc.Arguments

func NewDirectMessagePayload(dstPort uint64, message string, orderRef uint64) (p DirectMessagePayload, freeBytes int, err error) {
	p = DirectMessagePayload{
		{Name: rpc.RPC_DESTINATION_PORT, DataType: rpc.DataUint64, Value: dstPort}, // 0
		{Name: RPC_MKT_DM, DataType: rpc.DataString, Value: message},               // 1
	}

	if orderRef != 0 {
		p = append(p, rpc.Argument{Name: RPC_ORDER_ID_REF, DataType: rpc.DataUint64, Value: orderRef}) // 2
	}

	payloadSize, err := sizeArgs(rpc.Arguments(p))
	if err != nil {
		err = fmt.Errorf("error calculating payload size: %v", err)
		return
	}

	freeBytes = transaction.PAYLOAD0_LIMIT - payloadSize - 1
	bytesInExcess := -freeBytes - 1
	if bytesInExcess > 0 {
		err = fmt.Errorf("payload is %d bytes longer than allowed", bytesInExcess)
		return
	}

	return
}

func (p DirectMessagePayload) BuildTransferParams(receiverAddress string, deroAmount uint64, ringSize uint64) rpc.Transfer_Params {
	if ringSize == 0 {
		ringSize = DEFAULT_RING_SIZE
	}

	t := rpc.Transfer_Params{Transfers: []rpc.Transfer{}, Ringsize: ringSize}
	addTransferToTransferParams(receiverAddress, deroAmount, rpc.Arguments(p), &t)
	return t
}
