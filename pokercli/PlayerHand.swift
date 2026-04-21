//
//  PlayerHand.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

struct PlayerHand {
    let first: Card
    let second: Card

    func description() -> String {
        first.description() + " " + second.description()
    }
}
