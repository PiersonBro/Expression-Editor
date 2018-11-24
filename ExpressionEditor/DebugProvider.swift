//
//  DebugProvider.swift
//  ExpressionEditor
//
//  Created by EandZ on 8/22/17.
//  Copyright © 2017 EandZ. All rights reserved.
//

import Foundation
import VascularKit

struct DebugProvider: DataProvider {
    static var identifier: String = "Debug"
    
    func setupProvider() {}
    
    func execute(criteria: Criteria) -> DataProvider.Result {
        let rawInput = criteria.rawInput.components(separatedBy: CharacterSet.whitespacesAndNewlines).joined()
        if rawInput.count > 1 || rawInput.count == 0 {
            return ErrorResult(error: "Input didn't meet expectations")
        }
        
        return DebugResult(character: rawInput.first!, inputCriteria: criteria)
    }
    
    func execute(criteria: Criteria, completionHandler: @escaping (DataProvider.Result) -> ()) {
        let result = execute(criteria: criteria)
        completionHandler(result)
    }
}

struct DebugResult: DataResult {
    var properties: [String]
    let character: Character
    let initialResult: String
    let aheadChar: Character?
    let behindChar: Character?
    let inputCriteria: Criteria
    
    init(character: Character, inputCriteria: Criteria) {
        self.character = character
        self.initialResult = String(character)
        self.inputCriteria = inputCriteria
        (self.aheadChar, self.behindChar) = DebugResult.adjacentCharacters(character: character)
        properties = []
    }
    
    private static func adjacentCharacters(character: Character) -> (Character?, Character?) {
        let alphabet: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v","w", "x", "y", "z"]
        if let index = alphabet.index(of: character) {
            let aheadIndex = index + 1
            let behindIndex = index - 1
            let aheadChar: Character?
            if alphabet.valid(index: aheadIndex) {
                aheadChar = alphabet[aheadIndex]
            } else {
                aheadChar = nil
            }
            let behindChar: Character?
            if alphabet.valid(index: behindIndex) {
                behindChar = alphabet[behindIndex]
            } else {
                behindChar = nil
            }
            return (aheadChar, behindChar)
        } else {
            return (nil, nil)
        }
        
    }
    
    func getResult(property: String) -> DataResult {
        return initialResult
    }

}
