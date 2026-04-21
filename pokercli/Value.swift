//
//  Value.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

enum Value: Int, Equatable, Comparable, CaseIterable {
    case two   = 2
    case three = 3
    case four  = 4
    case five  = 5
    case six   = 6
    case seven = 7
    case eight = 8
    case nine  = 9
    case ten   = 10
    case jack  = 11
    case queen = 12
    case king  = 13
    case ace   = 14

    func display() -> String {
        switch self {
        case .two:   return "2"
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "10"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        }
    }

    static func < (lhs: Value, rhs: Value) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
