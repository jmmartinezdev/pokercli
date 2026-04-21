# pokercli

A macOS command-line sandbox for building Texas Hold'em poker logic in Swift. The model layer developed here is designed to be reused across iOS, macOS, and iPadOS apps.

## What's in the box

| File | Purpose |
|---|---|
| `Suit`, `Value`, `Card` | Core card primitives |
| `Deck` | 52-card deck with draw, discard, burn, and shuffle |
| `PlayerHand`, `CommunityCards` | Hole cards and board representation |
| `HandRank`, `HandEvaluator` | Hand classification and best-hand selection from 7 cards |
| `Player`, `Seat` | Player identity (persistent) and per-round seat state |
| `SidePot`, `Round` | Side-pot math and full dealing sequence for one hand |

`main.swift` is a scratchpad — it exercises whatever was most recently built and changes freely.

## Requirements

- Xcode 15+
- macOS 13+
- No external dependencies — pure Swift, no third-party packages

## Running

Open `pokercli.xcodeproj` in Xcode and press **Run** (⌘R), or build from the command line:

```bash
swift build
.build/debug/pokercli
```

## Current state

The dealing pipeline is complete: shuffle → post blinds → flop → turn → river → showdown → award pots (including side pots for all-ins). Hand evaluation covers all standard Texas Hold'em ranks through royal flush.

Betting actions (`bet`, `call`, `raise`, `fold`, `check`) and a `Game` entity to manage multiple rounds are the next things to build.
