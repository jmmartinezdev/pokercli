//
//  HandEvaluator.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

enum HandEvaluator {

    static func evaluate(hole: PlayerHand, community: CommunityCards) -> HandRank {
        let all = [hole.first, hole.second] + community.cards()
        precondition(all.count == 7, "Evaluation requires 2 hole cards and a complete 5-card board.")
        return bestRank(from: all)
    }

    // MARK: - Internals

    private static func bestRank(from cards: [Card]) -> HandRank {
        precondition(cards.count >= 5)
        var best: HandRank?
        combinations(of: cards, choosing: 5) { five in
            let candidate = rank(ofFive: five)
            if best == nil || candidate > best! {
                best = candidate
            }
        }
        return best!
    }

    private static func combinations(of cards: [Card], choosing k: Int, body: ([Card]) -> Void) {
        let n = cards.count
        var indices = Array(0..<k)
        while true {
            body(indices.map { cards[$0] })
            var i = k - 1
            while i >= 0 && indices[i] == n - k + i { i -= 1 }
            if i < 0 { return }
            indices[i] += 1
            for j in (i + 1)..<k { indices[j] = indices[j - 1] + 1 }
        }
    }

    private static func rank(ofFive cards: [Card]) -> HandRank {
        precondition(cards.count == 5)

        let valuesDesc = cards.map { $0.value }.sorted(by: >)

        var counts: [Value: Int] = [:]
        for v in valuesDesc { counts[v, default: 0] += 1 }

        let isFlush = Set(cards.map { $0.suit }).count == 1
        let straightHigh = detectStraight(valuesDesc: valuesDesc)

        if let high = straightHigh, isFlush {
            return .straightFlush(high: high)
        }

        let countPattern = counts.values.sorted(by: >)

        if countPattern == [4, 1] {
            let quad   = counts.first { $0.value == 4 }!.key
            let kicker = counts.first { $0.value == 1 }!.key
            return .fourOfAKind(quad: quad, kicker: kicker)
        }
        if countPattern == [3, 2] {
            let triple = counts.first { $0.value == 3 }!.key
            let pair   = counts.first { $0.value == 2 }!.key
            return .fullHouse(triple: triple, pair: pair)
        }
        if isFlush {
            return .flush(ranks: valuesDesc)
        }
        if let high = straightHigh {
            return .straight(high: high)
        }
        if countPattern == [3, 1, 1] {
            let triple  = counts.first { $0.value == 3 }!.key
            let kickers = counts.filter { $0.value == 1 }.map { $0.key }.sorted(by: >)
            return .threeOfAKind(triple: triple, kickers: kickers)
        }
        if countPattern == [2, 2, 1] {
            let pairs  = counts.filter { $0.value == 2 }.map { $0.key }.sorted(by: >)
            let kicker = counts.first { $0.value == 1 }!.key
            return .twoPair(high: pairs[0], low: pairs[1], kicker: kicker)
        }
        if countPattern == [2, 1, 1, 1] {
            let pair    = counts.first { $0.value == 2 }!.key
            let kickers = counts.filter { $0.value == 1 }.map { $0.key }.sorted(by: >)
            return .onePair(pair: pair, kickers: kickers)
        }
        return .highCard(ranks: valuesDesc)
    }

    private static func detectStraight(valuesDesc: [Value]) -> Value? {
        let unique = Array(Set(valuesDesc)).sorted(by: >)
        guard unique.count == 5 else { return nil }
        let raws = unique.map { $0.rawValue }
        if raws[0] - raws[4] == 4 { return unique[0] }
        // Ace-low wheel: A-2-3-4-5
        if raws == [14, 5, 4, 3, 2] { return .five }
        return nil
    }
}
