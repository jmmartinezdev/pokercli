//
//  Player.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

struct Player: Equatable {
    let id: Int
    var name: String
    var stack: Int

    // id is stable identity; stack changes every hand.
    static func == (lhs: Player, rhs: Player) -> Bool { lhs.id == rhs.id }
}
