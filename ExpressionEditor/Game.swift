//
//  Game.swift
//  MLBDataSource
//
//  Created by EandZ on 7/18/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

struct Game {
    private let inputLine: String
    let gameIndex: Int
    //TODO: Consider this as a `Date`.
    let date: String
    let score: String
    let ownerScore: Int
    let opponenetScore: Int
    // This is the record of the team that 'owns' the Game struct.
    // FIXME: This is fundamentally confusing.
    let record: String
    let didWin: Bool
    //The team that the team that owns this game played.
    let opponenet: Team
    let owner: Team
    
    //FIXME: Consider a different approach to teams rather than just passing it in here.
    init(inputLine: String, teams: [Team]) {
        self.inputLine = inputLine
        var line = Game.parse(line:inputLine)
        gameIndex = Int(String(line[line.startIndex]))!
        line.removeSubrange(line.startIndex...line.range(of: ".")!.upperBound)
        
        let dateRange = line.range(of: ",")!
        date = line[line.startIndex..<dateRange.lowerBound]
        line.removeSubrange(line.startIndex...dateRange.upperBound)
        
        let recordRangeBegin = line.range(of: "(")!
        let recordRangeEnd = line.range(of: ")")!
        record = line[recordRangeBegin.upperBound..<recordRangeEnd.lowerBound]
        line.removeSubrange(recordRangeBegin.lowerBound...recordRangeEnd.upperBound)
        
        if line.contains("lost to") {
            line.removeSubrange(line.range(of: "lost to ")!)
            didWin = false
        } else {
            didWin = true
            line.removeSubrange(line.range(of: "beat ")!)
        }
        
        let ownerRange = line.range(of: " ")!
        let ownerString = line[line.startIndex..<ownerRange.lowerBound]
        owner = Team.getTeam(fromInput: ownerString, teams: teams)!.first!
        line.removeSubrange(line.startIndex...ownerRange.lowerBound)
        
        let opponenetRange = line.range(of: ",")!
        let opponentString = line[line.startIndex..<opponenetRange.lowerBound]
        opponenet = Team.getTeam(fromInput: opponentString, teams: teams)!.first!
        line.removeSubrange(line.startIndex...opponenetRange.upperBound)
        score = line
        let dashRange = line.range(of: "-")!
        ownerScore = Int(String(line[line.startIndex..<dashRange.lowerBound]))!
        opponenetScore = Int(String(line[dashRange.upperBound..<line.endIndex]))!
    }
    
    static func parse(line: String) -> String {
        var line = line
        let range = line.range(of: "\"")!
        line.removeSubrange(line.startIndex...range.lowerBound)
        line.removeSubrange(line.startIndex...range.lowerBound)
        let newRange = line.range(of: "\"")!
        line.removeSubrange(newRange.lowerBound..<line.endIndex)
        
        return line
    }
}
