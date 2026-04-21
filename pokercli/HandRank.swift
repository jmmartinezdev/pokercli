//
//  HandRank.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

enum HandRank: Equatable, Comparable {
    case highCard(ranks: [Value])
    case onePair(pair: Value, kickers: [Value])
    case twoPair(high: Value, low: Value, kicker: Value)
    case threeOfAKind(triple: Value, kickers: [Value])
    case straight(high: Value)
    case flush(ranks: [Value])
    case fullHouse(triple: Value, pair: Value)
    case fourOfAKind(quad: Value, kicker: Value)
    case straightFlush(high: Value)

    func description() -> String {
        switch self {
        case .highCard(let ranks):
            return "High card, \(ranks[0].display())"
        case .onePair(let pair, _):
            return "Pair, \(pair.display())"
        case .twoPair(let high, let low, _):
            return "Two pair, \(high.display()) and \(low.display())"
        case .threeOfAKind(let triple, _):
            return "Three of a kind, \(triple.display())"
        case .straight(let high):
            return "Straight, \(high.display())-high"
        case .flush(let ranks):
            return "Flush, \(ranks[0].display())-high"
        case .fullHouse(let triple, let pair):
            return "Full house, \(triple.display()) over \(pair.display())"
        case .fourOfAKind(let quad, _):
            return "Four of a kind, \(quad.display())"
        case .straightFlush(let high):
            return high == .ace ? "Royal flush" : "Straight flush, \(high.display())-high"
        }
    }

    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.categoryRank != rhs.categoryRank {
            return lhs.categoryRank < rhs.categoryRank
        }
        return lhs.tiebreakers.lexicographicallyPrecedes(rhs.tiebreakers)
    }

    private var categoryRank: Int {
        switch self {
        case .highCard:       return 0
        case .onePair:        return 1
        case .twoPair:        return 2
        case .threeOfAKind:   return 3
        case .straight:       return 4
        case .flush:          return 5
        case .fullHouse:      return 6
        case .fourOfAKind:    return 7
        case .straightFlush:  return 8
        }
    }

    private var tiebreakers: [Value] {
        switch self {
        case .highCard(let ranks):                   return ranks
        case .onePair(let pair, let kickers):        return [pair] + kickers
        case .twoPair(let high, let low, let kick):  return [high, low, kick]
        case .threeOfAKind(let triple, let kickers): return [triple] + kickers
        case .straight(let high):                    return [high]
        case .flush(let ranks):                      return ranks
        case .fullHouse(let triple, let pair):       return [triple, pair]
        case .fourOfAKind(let quad, let kicker):     return [quad, kicker]
        case .straightFlush(let high):               return [high]
        }
    }
}
