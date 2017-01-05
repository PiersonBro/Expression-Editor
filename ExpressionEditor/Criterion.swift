//
//  Criterion.swift
//  MLBDataSource
//
//  Created by EandZ on 7/21/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

// An enum representing grammer specific to a criterionClause.
enum Grammer: String {
    case Verb
    case Number
    case Adverb
    case Adjective
    case Noun
    case Particle
    case OtherWord
    case Dash
    case Determiner
}

struct Criterion {
    typealias Word = (String, Grammer)
    let criterionClause: String
    let criterions: [Word]
    let teams: [Team]
    
    //FIXME: Figure some generalized natural language system out.
    // It is the responsibility of the Criterion struct to take input and transfrom it into something a machine can use
    init?(property: Property, criterionClause: [Word], teams: [Team]) {
        let words = criterionClause.map { $0.0 }
        self.criterionClause = words.joined(separator: " ")
        criterions = criterionClause
        self.teams = teams
    }
}
