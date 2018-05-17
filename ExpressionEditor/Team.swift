//
//  Team.swift
//  MLBDataSource
//
//  Created by EandZ on 6/5/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

struct Team {
    static func getTeam(fromInput: String, teams: [Team]) -> [Team]? {
        var fromInput = fromInput
        
        if fromInput == "WSN" {
            fromInput = "Nationals"
        }
       
        let inputTeams = teams.filter { team -> Bool in
            let firstName = team.json["first_name"].string!
            let lastName = team.json["last_name"].string!
            let fullName = firstName + " " + lastName
            
            if fullName == fromInput || fromInput == team.lastName || fromInput == firstName || fromInput == lastName || fromInput == team.abbreviatedName || firstName.score(word: fromInput) >= 0.6 || lastName.score(word: fromInput) >= 0.6 || fullName.score(word: fromInput) >= 0.6  {
                return true
            } else {
                return false
            }
        }
        
        if inputTeams.count == 0 {
            return nil
        }
        
        return inputTeams
    }
    

    static func fetchTeams(_ completionHandler: @escaping ([Team]) -> ()) {
        var request = URLRequest(url: URL(string: "https://erikberg.com/mlb/teams.json")!)
        request.setValue("MLBDataSource/1.0 (ezekiel.m.pierson@gmail.com)", forHTTPHeaderField: "User-Agent")
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders?["User-Agent"] = "MLBDataSource/1.0 (ezekiel.m.pierson@gmail.com)"
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                let teams = JSON.parse(NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String).array!.compactMap{ json -> Team? in
                    return Team(json: json)
                }
                completionHandler(teams)
            } else {
                print(error!)
            }
        }.resume()
    }
        
    // The teams name such as Mariners, Braves, Yankees, etc.
    let lastName: String
    // The three letter name of the team.
    let abbreviatedName: String
    let json: JSON
   
    //FIXME: Write this code.
    init?(json: JSON) {
        lastName = json["last_name"].string!
        abbreviatedName = json["abbreviation"].string!
        self.json = json
    }
}
