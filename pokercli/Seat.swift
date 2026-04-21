//
//  Seat.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

struct Seat {

    enum Status {
        case active, folded, allIn
    }

    var player: Player      // var: award() credits player.stack in place
    let hand: PlayerHand    // let: hole cards are immutable for the life of a hand
    var status: Status
    var streetBet: Int      // chips bet on the current street; reset to 0 by closeStreet()
    var committed: Int      // total chips committed to the pot across all streets this hand

    mutating func closeStreet() {
        committed += streetBet
        streetBet = 0
    }

    mutating func fold() {
        status = .folded
    }

    mutating func placeBet(amount: Int) {
        let chips = min(amount, player.stack)
        player.stack -= chips
        streetBet   += chips
        if player.stack == 0 { status = .allIn }
    }
}
