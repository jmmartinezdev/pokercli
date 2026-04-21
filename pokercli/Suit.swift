//
//  Suit.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

enum Suit: Equatable, CaseIterable {
    case hearts
    case clubs
    case diamonds
    case spades

    func symbol() -> String {
        switch self {
        case .hearts:   return "♥︎"
        case .clubs:    return "♣︎"
        case .diamonds: return "♦︎"
        case .spades:   return "♠︎"
        }
    }
}
