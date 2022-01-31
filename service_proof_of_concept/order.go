package main

import (
	"crypto/rand"
	"encoding/binary"
	"fmt"

	"github.com/deroproject/derohe/rpc"
	"github.com/deroproject/derohe/transaction"
)

type OrderPayloads []rpc.Arguments

func NewOrderPayloads(dstPort uint64, SCID string, orderID uint64, orderContent string) (payloads OrderPayloads, err error) {
	if orderID == 0 {
		orderID = getRandomOrderID()
	}

	var (
		payload         rpc.Arguments
		payloadSize     int
		freeBytes       int
		lastByte        int
		maxBytes        int
		content         string
		orderPart       = uint64(1)
		orderContentLen = len(orderContent)
	)

	for {
		payload = rpc.Arguments{
			{Name: rpc.RPC_DESTINATION_PORT, DataType: rpc.DataUint64, Value: dstPort}, // 0
			{Name: RPC_ORDER_ID, DataType: rpc.DataUint64, Value: orderID},             // 1
			{Name: RPC_ORDER_PART, DataType: rpc.DataUint64, Value: orderPart},         // 2
			{Name: RPC_ORDER_CONTENT, DataType: rpc.DataString, Value: ""},             // 3
		}

		if orderPart == 1 {
			payload = append(payload, rpc.Argument{Name: RPC_MKT_SCID, DataType: rpc.DataString, Value: SCID}) // 4
		}

		payloadSize, err = sizeArgs(payload)
		if err != nil {
			err = fmt.Errorf("error calculating payload size: %v", err)
			return
		}

		freeBytes = transaction.PAYLOAD0_LIMIT - payloadSize - 1
		if freeBytes < 0 {
			err = fmt.Errorf("payload is too long") // this should never happen if regular params are provided.
			return
		}
		if freeBytes == 0 {
			payloads = append(payloads, payload)
			orderPart++
			continue
		}

		maxBytes = lastByte + freeBytes
		if maxBytes > orderContentLen {
			maxBytes = orderContentLen
		}

		content = orderContent[lastByte:maxBytes]
		payload[3].Value = content

		if maxBytes < orderContentLen {
			lastByte = maxBytes
			payloads = append(payloads, payload)
			orderPart++
		} else { // is last part
			payload[2].Name = RPC_ORDER_FINAL_PART // renames argument PART to FINAL_PART to signal this is the final payload
			payloads = append(payloads, payload)
			break
		}
	}

	return
}

func (payloads OrderPayloads) BuildTransferParams(vendorAddress string, deroAmount uint64, ringSize uint64) rpc.Transfer_Params {
	if ringSize == 0 {
		ringSize = DEFAULT_RING_SIZE
	}
	t := rpc.Transfer_Params{Transfers: []rpc.Transfer{}, Ringsize: ringSize}

	amount := uint64(1)

	for _, p := range payloads {
		if p.HasValue(RPC_ORDER_FINAL_PART, rpc.DataUint64) {
			amount = deroAmount // sends the actual amount of coins to pay for the order only in the final part
		}
		addTransferToTransferParams(vendorAddress, amount, p, &t)
	}
	return t
}

// Credits to GetRandomIAddress8 func https://github.com/deroproject/derohe/blob/main/walletapi/wallet.go#L189 for the code.
func getRandomOrderID() uint64 {
	var id [8]byte
	rand.Read(id[:])
	return binary.BigEndian.Uint64(id[:])
}
