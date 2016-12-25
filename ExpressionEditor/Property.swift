//
//  File.swift
//  MLBDataSource
//
//  Created by EandZ on 7/4/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

extension Team {
    func getLines() -> [String] {
        let abbreiviatedName: String
        if lastName == "Nationals" {
            abbreiviatedName = "WSN"
        } else {
            abbreiviatedName = abbreviatedName
        }
        let url = URL(string:"http://www.baseball-reference.com/teams/\(abbreiviatedName)/2016-schedule-scores.shtml")!
        let data = try? Data(contentsOf: url)
        let string = String(data: data!, encoding: .utf8)!
        return string.components(separatedBy: .newlines)
    }
}

struct PythagAction: ActionType {
    let team: Team
    
    init(team: Team) {
        self.team = team
    }
    
    func execute(criterion: Criterion?) -> String {
        let lines = team.getLines()
        let line = lines.filter {
            $0.contains("<p><strong>")
        }.first!
        
        let index = lines.index(of: line)
        let sublines = Array(lines[index!..<lines.endIndex])
        let lineOne = sublines[6]
       
        let htmlStripper = HTMLStripper(html: lineOne)
        let values = htmlStripper.start()
        let pythagResults = values.filter {
            !($0.characters.count <= 1)
        }
        
        return pythagResults[1] + pythagResults[2]
    }
}

struct RecordAction: ActionType {
    let team: Team
    
    init(team: Team) {
        self.team = team
    }
    
    func execute(criterion: Criterion?) -> String {
        if let criterion = criterion, criterion.criterionClause != "", criterion.criterionClause.components(separatedBy: " ").count > 1 {
            let gameAction = GameRecordAction(team: team)
            return gameAction.execute(criterion: criterion)
        }
        
        let lines = team.getLines()
        let line = lines.filter {
            $0.contains("<p><strong>")
        }.first!
        
        let index = lines.index(of: line)
        let sublines = Array(lines[index!..<lines.endIndex])
        let lineOne = sublines[0]
        let htmlStripper = HTMLStripper(html: lineOne)
        
        let values = htmlStripper.start()
        let results = values.filter {
            !($0.characters.count <= 1)
        }
        
        return results[0]
    }
}

func scoreExpression(_ score: Int) -> (@escaping (Int, Int) -> Bool) -> (Int) -> Bool {
    let expr: ((_ equals: @escaping (Int, Int) -> Bool) -> (Int) -> Bool) = { equals in
        { number in
            return equals(number, score)
        }
    }
    
    return expr
}
// A game record action is a more fine grained way to find a record.
struct GameRecordAction: ActionType {
    let team: Team
    
    init(team: Team) {
        self.team = team
    }
    
    func getGames(teams: [Team]) -> [Game] {
        let lines = team.getLines()
        var gameLines = lines.filter {
            $0.contains("beat") || $0.contains("lost")
        }
        gameLines.removeFirst()
        
        return gameLines.map { Game(inputLine: $0, teams: teams) }
    }
    
    func execute(criterion: Criterion?) -> String {
        if let criterion = criterion {
            let games = getGames(teams: criterion.teams)

            print(criterion.criterionClause)
            return parse(criterion: criterion, games: games)
        } else {
            return "You have fallen into an unkown part of this app!" 
        }
    }
    
    static let verbs = ["score", "index", "date"]
    
    func parse(criterion: Criterion, games: [Game]) -> String {
        var scoreExpr: ((Int) -> (@escaping (Int, Int) -> Bool) -> (Int) -> Bool)? = nil
        var scoreAdded: ((@escaping (Int, Int) -> Bool) -> (Int) -> Bool)? = nil
        var boolExprAdded: ((Int) -> Bool)? = nil
        
        criterion.criterions.forEach {
            switch $0.1 {
                case .Verb:
                    if GameRecordAction.verbs[0] == $0.0 {
                        scoreExpr = scoreExpression
                    }
                case .Number:
                    if let scoreExpr = scoreExpr {
                        let number = Int($0.0)!
                        scoreAdded = scoreExpr(number)
                    }
                case .OtherWord, .Dash:
                    if let scoreAdded = scoreAdded {
                        let operation: ((Int, Int) -> Bool)?
                       
                        if $0.0 == "+" {
                            operation = (>=)
                        } else if $0.0 == "-" {
                            operation = (<=)
                        } else {
                            operation = nil
                        }
                        
                        if let operation = operation {
                            boolExprAdded = scoreAdded(operation)
                        }
                    }
                default:
                    break
            }
        }
        
        if let scoreAdded = scoreAdded, boolExprAdded == nil {
            boolExprAdded = scoreAdded(==)
        }
        
        if let boolExprAdded = boolExprAdded {
            let filteredGames = games.filter { game in
                return boolExprAdded(game.ownerScore)
            }
            var losses = 0
            var wins = 0
            
            filteredGames.forEach {
                if $0.didWin {
                    wins += 1
                } else {
                    losses += 1
                }
            }
            
            return "\(wins)-\(losses)"
        }
        
        return "Haha you failed"
    }
}

protocol ActionType {
    func execute(criterion: Criterion?) -> String
}

// FIXME: Add wrc+, etc.
enum Action: String {
    case record
    case pythag
}

struct Property {
    let action: Action
    
    init?(property: String) {
        let input = property.trimmingCharacters(in: CharacterSet.newlines)
        if let action = Action(rawValue: input) {
            self.action = action
        } else {
            return nil
        }
    }
    
    func execute(team: Team, criterion: Criterion?) -> String {
        let actionType = actionTypeFrom(action: action, team: team)
        return actionType.execute(criterion: criterion)
    }
    
    
    private func actionTypeFrom(action: Action, team: Team) -> ActionType {
        switch action {
            case .record:
                return RecordAction(team: team)
            case .pythag:
                return PythagAction(team: team)
        }
    }
}
