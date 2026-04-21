//
//  main.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

import Foundation

// Demo: 3-handed hand exercising fold / check / call / bet / raise
// across all four betting streets, ending in an awarded showdown.

let players = [
    Player(id: 1, name: "Alice", stack: 1000),  // BTN
    Player(id: 2, name: "Bob",   stack: 1000),  // SB
    Player(id: 3, name: "Carol", stack: 1000),  // BB
]

let round = Round(players: players, dealerIndex: 0, blinds: (small: 5, big: 10))

func dumpState(_ label: String) async {
    print("\n── \(label) ──")
    print("Community: \(await round.community.description())")
    print("Pot: \(await round.potTotal)")
    for seat in await round.seats {
        print("  \(seat.player.name): stack=\(seat.player.stack)  streetBet=\(seat.streetBet)  committed=\(seat.committed)  \(seat.status)")
    }
}

// Preflop: Alice raises, both blinds call.
await round.preFlop()
await round.raise(seatIndex: 0, to: 30)
await round.call(seatIndex: 1)
await round.call(seatIndex: 2)
await dumpState("Preflop closed")

// Flop: Bob checks, Carol bets, Alice raises, Bob folds, Carol calls.
await round.flop()
await round.check(seatIndex: 1)
await round.bet(seatIndex: 2, amount: 40)
await round.raise(seatIndex: 0, to: 120)
await round.fold(seatIndex: 1)
await round.call(seatIndex: 2)
await dumpState("Flop closed")

// Turn: both check.
await round.turn()
await round.check(seatIndex: 2)
await round.check(seatIndex: 0)
await dumpState("Turn closed")

// River: Carol bets, Alice calls.
await round.river()
await round.bet(seatIndex: 2, amount: 200)
await round.call(seatIndex: 0)
await dumpState("River closed")

// Showdown.
let results = await round.award()
print("\n── Winners ──")
for r in results {
    print("  \(r.seat.player.name) wins \(r.winnings)")
}

print("\n── Final stacks ──")
for seat in await round.seats {
    print("  \(seat.player.name): \(seat.player.stack)")
}
