//
//  File.swift
//  MLBDataSource
//
//  Created by EandZ on 7/4/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

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
