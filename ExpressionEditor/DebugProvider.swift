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
        if rawInput.characters.count > 1 || rawInput.characters.count == 0 {
            return ErrorResult(error: "Input didn't meet expectations")
        }
        
        return DebugResult(character: rawInput.characters.first!)
    }
    
    
}

struct DebugResult: DataResult {
    var properties: [String]
    let character: Character
    let initialResult: String
    let aheadChar: Character?
    let behindChar: Character?
    
    init(character: Character) {
        self.character = character
        self.initialResult = String(character)
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
    
    func getResult(property: String) -> String {
        return initialResult
    }

}
