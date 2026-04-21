//
//  SidePot.swift
//  pokercli
//
//  Created by Chema Martinez on 21/4/26.
//

struct SidePot {
    let amount: Int
    let eligible: [Seat]    // non-folded seats that contributed at this level
}
