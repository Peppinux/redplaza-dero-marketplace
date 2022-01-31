package main

import (
	"fmt"
	"time"

	"github.com/deroproject/derohe/rpc"
)

type ReceivedMessage struct {
	In       bool
	Amount   uint64
	Message  string
	OrderRef uint64
}

func processDirectMessages(destPort uint64) {
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

			message := ReceivedMessage{
				In:     e.Incoming,
				Amount: e.Amount,
			}

			// TODO: add elses with errors
			if e.Payload_RPC.HasValue(RPC_MKT_DM, rpc.DataString) {
				message.Message = e.Payload_RPC.Value(RPC_MKT_DM, rpc.DataString).(string)
			}

			if e.Payload_RPC.HasValue(RPC_ORDER_ID_REF, rpc.DataUint64) {
				message.OrderRef = e.Payload_RPC.Value(RPC_ORDER_ID_REF, rpc.DataUint64).(uint64)
			}

			fmt.Println(message) // TODO: Do something useful with the message instead of just printing

			h, err := getHeight()
			if err != nil {
				panic(err)
			}

			lastScannedHeight = h
		}
	}
}
