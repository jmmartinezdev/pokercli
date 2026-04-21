//
//  CommunityCards.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

struct CommunityCards {
    let flop: (Card, Card, Card)?
    let turn: Card?
    let river: Card?

    init(flop: (Card, Card, Card)? = nil, turn: Card? = nil, river: Card? = nil) {
        self.flop = flop
        self.turn = turn
        self.river = river
    }

    func cards() -> [Card] {
        var result: [Card] = []
        if let (c1, c2, c3) = flop { result += [c1, c2, c3] }
        if let t = turn             { result.append(t) }
        if let r = river            { result.append(r) }
        return result
    }

    func description() -> String {
        cards().map { $0.description() }.joined(separator: " ")
    }
}
