//
//  Card.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

struct Card: Equatable, Comparable {
    let suit: Suit
    let value: Value

    init(suit: Suit, value: Value) {
        self.suit = suit
        self.value = value
    }

    func description() -> String {
        value.display() + suit.symbol()
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.suit == rhs.suit && lhs.value == rhs.value
    }

    static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.value < rhs.value
    }
}
