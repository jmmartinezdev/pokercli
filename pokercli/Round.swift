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

    private var currentBet: Int { seats.map(\.streetBet).max() ?? 0 }

    private var isBettingStreet: Bool {
        switch phase {
        case .preFlop, .flop, .turn, .river: return true
        case .idle, .showdown:                return false
        }
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
        seats[smallBlindIndex].placeBet(amount: blinds.small)
        seats[bigBlindIndex].placeBet(amount: blinds.big)
        phase = .preFlop
    }

    func flop() {
        precondition(phase == .preFlop, "flop() requires preFlop() to have been called.")
        closeStreet()
        deck.burn()
        let c1 = drawRequired()
        let c2 = drawRequired()
        let c3 = drawRequired()
        community = CommunityCards(flop: (c1, c2, c3))
        phase = .flop
    }

    func turn() {
        precondition(phase == .flop, "turn() requires flop() to have been called.")
        closeStreet()
        deck.burn()
        let t = drawRequired()
        community = CommunityCards(flop: community.flop, turn: t)
        phase = .turn
    }

    func river() {
        precondition(phase == .turn, "river() requires turn() to have been called.")
        closeStreet()
        deck.burn()
        let r = drawRequired()
        community = CommunityCards(flop: community.flop, turn: community.turn, river: r)
        phase = .river
    }

    // MARK: - Actions

    func fold(seatIndex: Int) {
        precondition(isBettingStreet, "fold() requires an active betting street.")
        precondition(seats.indices.contains(seatIndex), "seatIndex out of range.")
        precondition(seats[seatIndex].status == .active, "Seat is not active.")
        seats[seatIndex].fold()
    }

    func check(seatIndex: Int) {
        precondition(isBettingStreet, "check() requires an active betting street.")
        precondition(seats.indices.contains(seatIndex), "seatIndex out of range.")
        precondition(seats[seatIndex].status == .active, "Seat is not active.")
        precondition(seats[seatIndex].streetBet == currentBet,
                     "Cannot check: a bet is open — call, raise, or fold.")
    }

    func call(seatIndex: Int) {
        precondition(isBettingStreet, "call() requires an active betting street.")
        precondition(seats.indices.contains(seatIndex), "seatIndex out of range.")
        precondition(seats[seatIndex].status == .active, "Seat is not active.")
        let delta = currentBet - seats[seatIndex].streetBet
        precondition(delta > 0, "Cannot call: nothing to call — check instead.")
        seats[seatIndex].placeBet(amount: delta)
    }

    func bet(seatIndex: Int, amount: Int) {
        precondition(isBettingStreet, "bet() requires an active betting street.")
        precondition(seats.indices.contains(seatIndex), "seatIndex out of range.")
        precondition(seats[seatIndex].status == .active, "Seat is not active.")
        precondition(currentBet == 0, "Cannot bet: a bet is already open — raise instead.")
        precondition(amount >= blinds.big, "Bet must be at least one big blind.")
        seats[seatIndex].placeBet(amount: amount)
    }

    func raise(seatIndex: Int, to total: Int) {
        precondition(isBettingStreet, "raise() requires an active betting street.")
        precondition(seats.indices.contains(seatIndex), "seatIndex out of range.")
        precondition(seats[seatIndex].status == .active, "Seat is not active.")
        precondition(currentBet > 0, "Cannot raise: no bet is open — bet instead.")
        precondition(total >= 2 * currentBet, "Raise must be at least 2× the current bet.")
        let delta = total - seats[seatIndex].streetBet
        precondition(delta > 0, "Raise must increase this seat's street bet.")
        seats[seatIndex].placeBet(amount: delta)
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
        closeStreet()
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

    private func drawRequired() -> Card {
        guard let card = deck.draw() else {
            preconditionFailure("Deck ran out of cards during round.")
        }
        return card
    }
}
