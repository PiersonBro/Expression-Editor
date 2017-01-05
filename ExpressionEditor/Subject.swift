//
//  Subject.swift
//  MLBDataSource
//
//  Created by EandZ on 7/21/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

struct Subject {
    let team: Team
    let property: Property
    let criterion: Criterion?
    let isAmbiguous: Bool
    
    init?(words: [Criterion.Word], teams: [Team]) {
        var criterionWords: [Criterion.Word] = Array<Criterion.Word>()
        var teamNeedle: Team? = nil
        var propertyNeedle: Property? = nil
        var ambiguousTeams = [Team]()
        
        words.forEach { word, meaning -> Void in
            if let teams = Team.getTeam(fromInput: word, teams: teams), teamNeedle == nil && ambiguousTeams.count == 0  {
                if teams.count == 1 {
                    teamNeedle = teams.first!
                    return
                } else {
                    ambiguousTeams = teams
                }
            } else if let property = Property(property: word), propertyNeedle == nil {
                propertyNeedle = property
            } else {
                criterionWords.append((word, meaning))
            }
        }
        
        if ambiguousTeams.count > 0 {
            let allInput = words.reduce("") { reducer, word -> String in
                if reducer == "" {
                    return reducer + word.0
                } else {
                    return reducer + " " + word.0
                }
            }
            let newTeams = ambiguousTeams.filter { allInput.contains($0.lastName) }
            
            if newTeams.count != 1 {
                isAmbiguous = true
            } else {
                isAmbiguous = false
            }
            
            teamNeedle = newTeams.first ?? ambiguousTeams.first
        } else {
            isAmbiguous = false
        }

        guard let newTeamNeedle = teamNeedle, let newPropertyNeedle = propertyNeedle else {
            return nil
        }
        
        team = newTeamNeedle
        property = newPropertyNeedle
        criterion = Criterion(property: property, criterionClause: criterionWords, teams: teams)
    }
    
    func execute(completionHandler: (String) -> ()) {
        if isAmbiguous {
            completionHandler("Error: Ambiguous Input")
            return
        }
        
        
        completionHandler(property.execute(team: team, criterion: criterion!))
    }
}
