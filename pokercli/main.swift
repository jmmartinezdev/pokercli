//
//  main.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

import Foundation

// Demo: blinds posted during preFlop() for a 4-handed table.
// Dealer is Bob (index 1); small blind = Carol (2), big blind = Dave (3).

let players = [
    Player(id: 1, name: "Alice", stack: 1000),
    Player(id: 2, name: "Bob",   stack: 1000),
    Player(id: 3, name: "Carol", stack: 1000),
    Player(id: 4, name: "Dave",  stack: 1000),
]

let round = Round(players: players, dealerIndex: 1, blinds: (small: 5, big: 10))

await round.preFlop()

print("Dealer:      \(players[round.dealerIndex].name)")
print("Small blind: \(players[await round.smallBlindIndex].name)")
print("Big blind:   \(players[await round.bigBlindIndex].name)")

print("\nSeats after preFlop():")
for seat in await round.seats {
    print("  \(seat.player.name): stack=\(seat.player.stack), streetBet=\(seat.streetBet), \(seat.hand.description())")
}

print("\nPot: \(await round.potTotal)")

// Heads-up check: dealer posts the small blind.
let duo = [players[0], players[1]]
let heads = Round(players: duo, dealerIndex: 0, blinds: (small: 5, big: 10))
await heads.preFlop()
print("\nHeads-up (dealer=\(duo[heads.dealerIndex].name)):")
print("  Small blind: \(duo[await heads.smallBlindIndex].name)")
print("  Big blind:   \(duo[await heads.bigBlindIndex].name)")
