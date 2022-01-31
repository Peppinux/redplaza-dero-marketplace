package main

import (
	"fmt"
	"time"

	"github.com/deroproject/derohe/rpc"
)

type ReceivedOrderPart struct {
	In          bool
	Amount      uint64
	ID          uint64
	Part        uint64
	IsFinalPart bool
	Content     string
	SCID        string
}

type ReceivedOrder struct {
	Parts       map[uint64]ReceivedOrderPart
	TotalAmount uint64
}

func processOrders(destPort uint64) {
	fmt.Println("asd")

	var lastScannedHeight uint64 = 0 // todo inizialmente dovrebbe corrispondere ad height di creazione smart contract piuttosto che zero

	for {
		time.Sleep(time.Second)

		fmt.Println("esd")
		t, err := getTransfers(rpc.Get_Transfers_Params{
			Coinbase:        false,
			In:              true,
			Out:             true,
			Min_Height:      lastScannedHeight,
			DestinationPort: destPort,
		})
		if err != nil {
			panic(err)
		}

		// todo aggiungere comunque controlli manuali su Entries dato che non so se min height e dest port sono stati implementati

		for _, e := range t.Entries {
			if e.Coinbase {
				continue
			}

			if e.Height < lastScannedHeight {
				continue
			}

			if !e.Payload_RPC.HasValue(rpc.RPC_DESTINATION_PORT, rpc.DataUint64) {
				if e.Payload_RPC.Value(rpc.RPC_DESTINATION_PORT, rpc.DataUint64).(uint64) != destPort {
					continue
				}
			}

			order := ReceivedOrder{
				Parts:       map[uint64]ReceivedOrderPart{},
				TotalAmount: 0,
			}

			orderPart := ReceivedOrderPart{
				In:     e.Incoming,
				Amount: e.Amount,
			}

			// TODO: add elses with errors
			if e.Payload_RPC.HasValue(RPC_ORDER_ID, rpc.DataUint64) {
				orderPart.ID = e.Payload_RPC.Value(RPC_ORDER_ID, rpc.DataUint64).(uint64)
			}
			if e.Payload_RPC.HasValue(RPC_ORDER_PART, rpc.DataUint64) {
				orderPart.Part = e.Payload_RPC.Value(RPC_ORDER_PART, rpc.DataUint64).(uint64)
				orderPart.IsFinalPart = false
			}
			if e.Payload_RPC.HasValue(RPC_ORDER_FINAL_PART, rpc.DataUint64) {
				orderPart.Part = e.Payload_RPC.Value(RPC_ORDER_FINAL_PART, rpc.DataUint64).(uint64)
				orderPart.IsFinalPart = true
			}
			if e.Payload_RPC.HasValue(RPC_ORDER_CONTENT, rpc.DataString) {
				orderPart.Content = e.Payload_RPC.Value(RPC_ORDER_CONTENT, rpc.DataString).(string)
			}
			if e.Payload_RPC.HasValue(RPC_MKT_SCID, rpc.DataString) {
				orderPart.SCID = e.Payload_RPC.Value(RPC_MKT_SCID, rpc.DataUint64).(string)
			}

			order.Parts[orderPart.ID] = orderPart
			order.TotalAmount += orderPart.Amount

			fmt.Printf("%+v", order) // TODO: Do something useful with the order instead of just printing

			h, err := getHeight()
			if err != nil {
				panic(err)
			}

			lastScannedHeight = h
		}
	}
}
