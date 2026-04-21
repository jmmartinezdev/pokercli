//
//  Round.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

actor Round {

    // MARK: - Types

    enum Phase {
        case idle, preFlop, flop, turn, river, showdown
    }

    // MARK: - Properties

    var deck: Deck
    let players: [Player]
    var seats: [Seat]
    var community: CommunityCards
    var phase: Phase
    let dealerIndex: Int
    let blinds: (small: Int, big: Int)

    // MARK: - Computed

    var potTotal: Int { seats.reduce(0) { $0 + $1.committed + $1.streetBet } }

    // Heads-up: dealer posts small blind, non-dealer posts big blind.
    var smallBlindIndex: Int {
        players.count == 2 ? dealerIndex : (dealerIndex + 1) % players.count
    }
    var bigBlindIndex: Int {
        players.count == 2 ? (dealerIndex + 1) % players.count
                           : (dealerIndex + 2) % players.count
    }

    // MARK: - Init

    init(players: [Player], dealerIndex: Int, blinds: (small: Int, big: Int)) {
        precondition(players.count >= 2, "A round requires at least two players.")
        precondition((0..<players.count).contains(dealerIndex), "dealerIndex out of range.")
        precondition(blinds.small >= 0 && blinds.big >= blinds.small, "Invalid blinds.")
        self.deck = Deck()
        self.players = players
        self.seats = []
        self.community = CommunityCards()
        self.phase = .idle
        self.dealerIndex = dealerIndex
        self.blinds = blinds
    }

    // For scratchpad / testing: construct a Round with pre-built state.
    init(players: [Player],
         seats: [Seat],
         community: CommunityCards,
         phase: Phase,
         dealerIndex: Int = 0,
         blinds: (small: Int, big: Int) = (0, 0)) {
        self.deck = Deck()
        self.players = players
        self.seats = seats
        self.community = community
        self.phase = phase
        self.dealerIndex = dealerIndex
        self.blinds = blinds
    }

    // MARK: - Dealing

    func preFlop() {
        precondition(phase == .idle, "preFlop() must be the first action in a round.")
        deck.shuffle()
        var built: [Seat] = []
        built.reserveCapacity(players.count)
        for player in players {
            let first  = drawRequired()
            let second = drawRequired()
            built.append(Seat(player: player,
                              hand: PlayerHand(first: first, second: second),
                              status: .active,
                              streetBet: 0,
                              committed: 0))
        }
        seats = built
        postBlind(seatIndex: smallBlindIndex, amount: blinds.small)
        postBlind(seatIndex: bigBlindIndex,   amount: blinds.big)
        phase = .preFlop
    }

    func flop() {
        precondition(phase == .preFlop, "flop() requires preFlop() to have been called.")
        deck.burn()
        let c1 = drawRequired()
        let c2 = drawRequired()
        let c3 = drawRequired()
        community = CommunityCards(flop: (c1, c2, c3))
        phase = .flop
    }

    func turn() {
        precondition(phase == .flop, "turn() requires flop() to have been called.")
        deck.burn()
        let t = drawRequired()
        community = CommunityCards(flop: community.flop, turn: t)
        phase = .turn
    }

    func river() {
        precondition(phase == .turn, "river() requires turn() to have been called.")
        deck.burn()
        let r = drawRequired()
        community = CommunityCards(flop: community.flop, turn: community.turn, river: r)
        phase = .river
    }

    // MARK: - Showdown

    func sidePots() -> [SidePot] {
        let levels = Array(Set(seats.map { $0.committed }.filter { $0 > 0 })).sorted()
        var result: [SidePot] = []
        var prevLevel = 0
        for level in levels {
            let contributors = seats.filter { $0.committed >= level }
            let amount = (level - prevLevel) * contributors.count
            let eligible = contributors.filter { $0.status != .folded }
            if amount > 0 {
                result.append(SidePot(amount: amount, eligible: eligible))
            }
            prevLevel = level
        }
        return result
    }

    func award() -> [(seat: Seat, winnings: Int)] {
        precondition(phase == .river, "award() requires river() to have been dealt.")
        let pots = sidePots()
        var perSeat: [Int: Int] = [:]

        for pot in pots {
            let ranked = pot.eligible.map { seat -> (Seat, HandRank) in
                (seat, HandEvaluator.evaluate(hole: seat.hand, community: community))
            }
            guard let best = ranked.map({ $0.1 }).max() else { continue }
            let winners = ranked.filter { $0.1 == best }.map { $0.0 }

            let share     = pot.amount / winners.count
            let remainder = pot.amount % winners.count

            for winner in winners {
                let i = seats.firstIndex { $0.player == winner.player }!
                perSeat[i, default: 0] += share
            }

            // Odd chip goes to the first tied winner clockwise from the dealer.
            let count = seats.count
            let start = (dealerIndex + 1) % count
            var remainderIdx = start
            for offset in 0..<count {
                let idx = (start + offset) % count
                if winners.contains(where: { $0.player == seats[idx].player }) {
                    remainderIdx = idx
                    break
                }
            }
            perSeat[remainderIdx, default: 0] += remainder
        }

        var result: [(seat: Seat, winnings: Int)] = []
        for i in seats.indices {
            guard let chips = perSeat[i], chips > 0 else { continue }
            seats[i].player.stack += chips
            result.append((seat: seats[i], winnings: chips))
        }

        phase = .showdown
        return result
    }

    // MARK: - Private

    private func closeStreet() {
        for i in seats.indices { seats[i].closeStreet() }
    }

    private func postBlind(seatIndex: Int, amount: Int) {
        let chips = min(amount, seats[seatIndex].player.stack)
        seats[seatIndex].player.stack -= chips
        seats[seatIndex].streetBet    = chips
        if seats[seatIndex].player.stack == 0 {
            seats[seatIndex].status = .allIn
        }
    }

    private func drawRequired() -> Card {
        guard let card = deck.draw() else {
            preconditionFailure("Deck ran out of cards during round.")
        }
        return card
    }
}
