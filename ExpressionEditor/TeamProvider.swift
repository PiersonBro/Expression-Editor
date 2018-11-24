//
//  TeamProvider.swift
//  ExpressionEditor
//
//  Created by EandZ on 8/11/17.
//  Copyright © 2017 EandZ. All rights reserved.
//

import Foundation
import VascularKit

public struct TeamResult: DataResult {
    public let properties: [String]
    
    public let initialResult: String
    
    public var inputCriteria: Criteria
    
    public func getResult(property: String) -> DataResult {
        return ""
    }
}

public class TeamProvider: DataProvider {
    private var teams: [Team]? = nil
    public required init() {}
    
    public func setupProvider() {
        Team.fetchTeams { teams in
            self.teams = teams
        }
    }
    
    public static var identifier: String = "MLB"
    
    public func execute(criteria: Criteria) -> DataProvider.Result {
        
        return TeamResult(properties: [""], initialResult: "", inputCriteria: criteria)
    }
    
    public func execute(criteria: Criteria, completionHandler: @escaping (DataProvider.Result) -> ()) {
        let result = execute(criteria: criteria)
        completionHandler(result)
    }
}
