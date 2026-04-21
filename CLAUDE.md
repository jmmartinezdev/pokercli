# pokercli — Development Notes

## Git workflow

**Always ask the user for confirmation before running `git commit` or `git push`.** Show them the changes first and wait for explicit approval. Push directly to `main` — no PRs.

A macOS command-line tool used as a sandbox for building the card/hand logic of a Texas Hold 'em poker game. The logic developed here is intended to be reused later in the iOS, macOS, and iPadOS apps.

## Project layout

```
pokercli/
├── pokercli.xcodeproj
└── pokercli/
    ├── Suit.swift
    ├── Value.swift
    ├── Card.swift
    ├── Deck.swift
    ├── PlayerHand.swift
    ├── CommunityCards.swift
    ├── HandRank.swift
    ├── HandEvaluator.swift
    ├── Player.swift
    ├── Seat.swift
    ├── SidePot.swift
    ├── Round.swift
    └── main.swift
```

One type per file. `main.swift` is used as a scratchpad to exercise the latest code.

## Entities built so far

### `Suit` — [Suit.swift](pokercli/Suit.swift)
- Enum: `.hearts`, `.clubs`, `.diamonds`, `.spades`.
- `symbol() -> String` returns the Unicode glyph (♥︎ ♣︎ ♦︎ ♠︎).
- Conforms to `Equatable`, `CaseIterable`.

### `Value` — [Value.swift](pokercli/Value.swift)
- Enum with `Int` raw values `2...14` (Ace = 14, high).
- Case order matches ranking for high-card comparisons.
- `display() -> String` returns the face label (`2`…`10`, `J`, `Q`, `K`, `A`).
- Conforms to `Equatable`, `Comparable` (via `rawValue`), `CaseIterable`.

### `Card` — [Card.swift](pokercli/Card.swift)
- Struct with `let suit: Suit` and `let value: Value`.
- `description() -> String` formatted as `"<value><suit-symbol>"` (e.g. `A♣︎`).
- `Equatable`: equal when both suit and value match.
- `Comparable`: ordered by `value` only (suit does not break ties — poker has no suit ranking).

### `PlayerHand` — [PlayerHand.swift](pokercli/PlayerHand.swift)
- Struct with `let first: Card` and `let second: Card` (hole cards).
- `description() -> String` returns both cards space-separated (e.g. `A♣︎ K♥︎`).
- Immutable once created; `Player` replaces it each round via `var hand: PlayerHand?`.
- No protocol conformances yet — equality and comparison belong to hand evaluation, not yet built.

### `Deck` — [Deck.swift](pokercli/Deck.swift)
- `struct` with `var availableCards: [Card]` and `var discardedCards: [Card]`.
- `init()` fills the 52-card deck by iterating `Suit.allCases × Value.allCases`; `discardedCards` starts empty.
- `mutating func draw() -> Card?` removes and returns the first card from `availableCards`; returns `nil` when empty.
- `mutating func discard(_ card: Card)` moves a card into `discardedCards`.
- `mutating func burn() -> Card?` removes the top card from `availableCards`, moves it to `discardedCards`, and returns it (`@discardableResult`); returns `nil` when the deck is empty.
- `mutating func shuffle()` merges `availableCards` and `discardedCards`, shuffles them into `availableCards`, and clears `discardedCards`.
- `print()` prints available and discarded cards in labelled sections with counts; uses `Swift.print` internally to avoid recursion.
- Was previously an `actor`; demoted to `struct` once `Round` became the owning actor — `Round`'s isolation already serialises all deck access, making a second layer of actor isolation redundant.

### `CommunityCards` — [CommunityCards.swift](pokercli/CommunityCards.swift)
- Struct with `let flop: (Card, Card, Card)?`, `let turn: Card?`, `let river: Card?`.
- Streets are optional to model a board that's only partially dealt; constructed fresh each street rather than mutated.
- `cards() -> [Card]` flattens whichever streets are present, in dealt order.
- `description() -> String` joins the dealt cards with spaces.
- No protocol conformances yet.

### `HandRank` — [HandRank.swift](pokercli/HandRank.swift)
- Enum describing an evaluated 5-card hand: `.highCard`, `.onePair`, `.twoPair`, `.threeOfAKind`, `.straight`, `.flush`, `.fullHouse`, `.fourOfAKind`, `.straightFlush`.
- Associated values carry the `Value`(s) needed for tie-breaking (kickers stored descending).
- Case order encodes category strength (low → high), mirroring the `Value: Int` pattern.
- Wheel straight represented as `.straight(high: .five)`; royal flush as `.straightFlush(high: .ace)` — no separate case.
- No suit stored — poker has no suit ranking, and storing it would invite misuse in comparisons.
- `description() -> String` gives a poker-style phrase (e.g. `"Full house, K over 7"`, `"Royal flush"`).
- `Equatable` (synthesized). `Comparable`: category first, then `lexicographicallyPrecedes` on the tiebreaker `[Value]`.

### `Player` — [Player.swift](pokercli/Player.swift)
- Struct with `let id: Int`, `var name: String`, `var stack: Int`.
- Persistent entity — lives above `Round` (will be owned by a future `Game`). Stack carries across rounds.
- `Equatable` with custom `==` comparing `id` only — stack changes; identity does not.
- No `UUID` (requires Foundation). `Int` IDs assigned by the caller (future `Game`).
- No `Comparable` — player ordering is seating position (array index in `Round.seats`), not an intrinsic property.

### `Seat` — [Seat.swift](pokercli/Seat.swift)
- Struct, round-scoped. Ties a `Player` to their hole cards and bet state for one hand.
- Nested `enum Status`: `.active`, `.folded`, `.allIn`. No raw value — cases are states, not a ranked order.
- `var player: Player` — mutable so `Round.award()` can credit `player.stack` in place.
- `let hand: PlayerHand` — immutable; hole cards don't change mid-hand.
- `var streetBet: Int` — chips bet on the current street; answers "what does it cost to call?". Reset to 0 by `closeStreet()`.
- `var committed: Int` — total chips put into the pot across all streets this hand; drives side-pot math and award.
- `mutating func closeStreet()` — folds `streetBet` into `committed` and resets it. Called by `Round` at the top of each dealing method (`flop`/`turn`/`river`) and at the top of `award()`.
- `mutating func fold()` — sets `status = .folded`. No chip movement.
- `mutating func placeBet(amount: Int)` — low-level chip mutator: caps at `player.stack`, decrements the stack, **adds** to `streetBet` (delta semantics), and promotes to `.allIn` if the stack hits 0. Used by `Round` for blinds and for every `call` / `bet` / `raise` action — the calling layer computes the delta; `Seat` itself knows nothing about `currentBet` or street state.
- Replaces `Round.playerHands: [PlayerHand]` as the round-scoped player record.

### `SidePot` — [SidePot.swift](pokercli/SidePot.swift)
- Struct with `let amount: Int` and `let eligible: [Seat]` (non-folded seats that contributed at this level).
- Computed result, never mutated. Produced by `Round.sidePots()` at showdown.
- Standard level-based algorithm: sort seats by `committed`, iterate unique levels; each level's pot = `(level − prevLevel) × contributorCount`; eligible = non-folded contributors at that level. This handles all-ins correctly without special cases.

### `Round` — [Round.swift](pokercli/Round.swift)
- `actor` that owns a full dealing sequence for one hand of Texas Hold'em.
- `init(players:dealerIndex:blinds:)` is the primary initialiser; caller (future `Game`) owns button movement and stake levels. A second `init(players:seats:community:phase:dealerIndex:blinds:)` exists for scratchpad / testing without dealing (the extra params default to `0` / `(0, 0)`).
- `var deck: Deck` — owned value; mutations are safe because they happen on `Round`'s executor.
- `var phase: Phase` — enum `.idle → .preFlop → .flop → .turn → .river → .showdown`; each method enforces the correct predecessor via `precondition`.
- `let players: [Player]` and `var seats: [Seat]` — `seats` is populated by `preFlop()`, one `Seat` per player.
- `let dealerIndex: Int` and `let blinds: (small: Int, big: Int)` — round-scoped button position and stake levels. `let` + `Sendable` means nonisolated (callers don't need `await` to read them).
- `var potTotal: Int` — computed: sum of all `seat.committed + seat.streetBet`. Display value; not the source of truth.
- `var smallBlindIndex` / `var bigBlindIndex` — computed from `dealerIndex`. Heads-up (2 players): dealer posts the small blind, non-dealer the big. 3+ players: `dealerIndex + 1` / `dealerIndex + 2` (mod `count`).
- `preFlop()` shuffles the deck, builds `seats` (status `.active`, `streetBet`/`committed` both 0), then posts blinds by calling `seats[i].placeBet(amount:)` directly — no helper needed; `placeBet` handles the `.allIn` promotion if a player can't cover.
- `flop()`, `turn()`, `river()` each call `closeStreet()` first (folding the previous street's bets into `committed`), then burn one card and deal the new street. `award()` also calls `closeStreet()` before computing pots.
- **Betting actions** — `fold(seatIndex:)`, `check(seatIndex:)`, `call(seatIndex:)`, `bet(seatIndex:amount:)`, `raise(seatIndex:to total:)`. All require `phase ∈ {.preFlop, .flop, .turn, .river}` and an `.active` seat; illegal inputs trip a `precondition`. `Round` owns all cross-seat logic (current bet level, min-bet/min-raise validation, delta computation) and delegates the actual chip movement to `Seat.placeBet(amount:)`. `bet` and `raise` take the *total* `streetBet` target the player wants to reach, not the delta — matching how poker UIs and rule language talk about bet sizing.
- Min-bet is one big blind; min-raise is `2 × currentBet`. This is a simplification — real poker's min-raise rule is "previous raise size", which requires tracking the last raise increment. Revisit when that becomes load-bearing.
- `private var currentBet: Int` — max `streetBet` across all seats, or 0 if nobody has bet this street. Drives `check`/`call`/`bet`/`raise` validation.
- `private var isBettingStreet: Bool` — guards all betting actions against `.idle` and `.showdown`.
- `func sidePots() -> [SidePot]` — derives main and side pots from per-seat `committed` values.
- `func award() -> [(seat: Seat, winnings: Int)]` — precondition: `phase == .river`. Calls `closeStreet()`, evaluates each eligible seat's best hand via `HandEvaluator`, awards each `SidePot`, credits `seat.player.stack`, sets `phase = .showdown`. Odd chip goes to the first tied winner clockwise from the dealer.
- `private func closeStreet()` — calls `seat.closeStreet()` on all seats.
- Action turn order is **not** enforced yet — `Round` will accept actions in any order as long as preconditions hold. Turn-order / action-pointer logic belongs to a later layer (probably `Game` or a dedicated `BettingRound`).
- All methods are synchronous (no `async`) — deck/seat access is local struct mutation. Callers outside the actor still need `await` for the isolation hop.
- Private `drawRequired() -> Card` crashes on an empty deck — running out of cards mid-round is a programming error.

### `HandEvaluator` — [HandEvaluator.swift](pokercli/HandEvaluator.swift)
- Caseless `enum` used as a Swift namespace — pure, stateless logic, no instances.
- `static func evaluate(hole: PlayerHand, community: CommunityCards) -> HandRank` is the only public entry point.
- Precondition: `community` must have flop + turn + river dealt (7 cards total). Partial boards are a programming error at this layer; pre-river "hand strength" is equity, a different problem.
- Internally enumerates all `C(7,5) = 21` 5-card subsets and returns the max `HandRank`. Naive enumeration is fine at this size — no lookup tables or bit tricks.
- Detects the A-2-3-4-5 wheel as a special case; everywhere else Ace is high.

## Design principles to keep following

1. **Raw values when they encode an order.** `Value: Int` lets `Comparable` delegate to `rawValue` — no switch tables, and case order doubles as ranking documentation.
2. **Protocol conformance only when it buys something concrete.** Each conformance so far exists for a named reason (equality checks, sorting, deck iteration, shuffling). Don't pre-adopt `Hashable`, `CustomStringConvertible`, `Codable`, etc. until a call site needs them.
3. **Model poker semantics faithfully.** `Card`'s `Comparable` ignores suit because poker does. If a future rule needs tie-breaking by suit (e.g. a specific variant), add a separate comparator rather than changing the default ordering.
4. **Actors for shared mutable game state.** `Round` is an actor because it is the externally-visible coordination point for a hand. Types that are only ever accessed from within one actor (like `Deck`) should be structs — the owning actor's isolation is sufficient protection.
5. **One type per file, minimal file header.** Match the existing style of the auto-generated header comments.
6. **No comments that restate the code.** Only comment on non-obvious *why* (e.g. "Ace = 14" would be worth a comment if it weren't already obvious from position).
7. **`main.swift` is a scratchpad.** Replace its contents freely to demo whatever was just built — don't accumulate old demos. The user may tweak it between turns; respect those edits.
8. **Use the tightest standard-library primitive available.** `Array.shuffle()`, `allCases`, `sorted()`, `reserveCapacity` — before writing custom loops or helpers.
9. **Answer design questions directly in chat.** When the user asks "should we do X?", give a concrete recommendation with the tradeoff, then implement. Don't leave the decision implicit in the code.
10. **Cross-platform portability.** This code will ship on iOS/macOS/iPadOS. Keep it in pure Swift with no `AppKit`/`UIKit`/`Foundation`-specific types in the model layer. `Foundation` is imported in `main.swift` only.

## Likely next steps (not yet built)

- **Action turn order** — `Round` currently accepts actions in any order. Need an action pointer (first to act per street, advancing around the table, skipping folded/all-in seats) plus a "betting round closed" detector (action returns to the last aggressor, or checks around).
- **Proper min-raise rule** — currently `2 × currentBet`; standard poker uses "size of the previous raise". Requires tracking `lastRaiseSize` per street.
- **Partial all-in raises** — when a player goes all-in for less than a full min-raise, action should not re-open for players who already acted. Needs turn-order first.
- **`Game` entity** — owns `[Player]` across rounds, creates a fresh `Round` each hand, transfers updated stacks back to players after `award()`.
- Returning the winning 5-card combination alongside the `HandRank` from `HandEvaluator.evaluate` — currently only the rank is returned, not which cards produced it.
- Partial-board hand strength / equity (different problem from `HandEvaluator`, which requires a complete board).
- Allowing `HandEvaluator` to evaluate hands on partial boards (flop-only, flop+turn) — requires relaxing the 7-card precondition and choosing the best hand from fewer than 7 cards.
- Later: UI layers for each Apple platform, sharing this model code.

When extending, check this file first and update it as new entities/decisions land.
