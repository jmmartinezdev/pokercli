//
//  Deck.swift
//  pokercli
//
//  Created by Chema Martinez on 20/4/26.
//

struct Deck {

    // MARK: - Properties

    var availableCards: [Card]
    var discardedCards: [Card]

    // MARK: - Init

    init() {
        var cards: [Card] = []
        cards.reserveCapacity(Suit.allCases.count * Value.allCases.count)
        for suit in Suit.allCases {
            for value in Value.allCases {
                cards.append(Card(suit: suit, value: value))
            }
        }
        self.availableCards = cards
        self.discardedCards = []
    }

    // MARK: - Card Management

    mutating func draw() -> Card? {
        guard !availableCards.isEmpty else { return nil }
        return availableCards.removeFirst()
    }

    mutating func discard(_ card: Card) {
        discardedCards.append(card)
    }

    @discardableResult
    mutating func burn() -> Card? {
        guard !availableCards.isEmpty else { return nil }
        let card = availableCards.removeFirst()
        discardedCards.append(card)
        return card
    }

    mutating func shuffle() {
        availableCards = (availableCards + discardedCards).shuffled()
        discardedCards = []
    }

    // MARK: - Debug

    func print() {
        Swift.print("Available cards (\(availableCards.count)):")
        for (index, card) in availableCards.enumerated() {
            Swift.print("\(index): \(card.description())")
        }
        Swift.print("Discarded cards (\(discardedCards.count)):")
        for (index, card) in discardedCards.enumerated() {
            Swift.print("\(index): \(card.description())")
        }
    }
}
