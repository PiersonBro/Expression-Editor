//
//  CombinationRepetition.swift
//  ExpressionEditor
//
//  Created by EandZ on 12/20/16.
//  Copyright © 2016 EandZ. All rights reserved.
//


func combinationRepetitionGuts(chosen: [Int], input: [Int], index: Int, r: Int, start: Int, end: Int) -> [Int] {
    var chosen = chosen
    
    if index == r {
        let result = (0..<r).map { i in
            input[chosen[i]]
        }
        print(result)
        return result
    }
    
    (start...end).forEach { num in
        chosen[index] = num
        combinationRepetitionGuts(chosen: chosen, input: input, index: index + 1, r: r, start: num, end: end)
    }
    return []
}

func combinationRepetition(input: [Int], index: Int, r: Int) -> [Int] {
    let chosen = Array(repeating: 0, count: r + 1)
    return combinationRepetitionGuts(chosen: chosen, input: input, index: 0, r: r, start: 0, end: index - 1)
}

//combinationRepetition(input: [1,2,3,4,5,6,7], index: 7, r: 12)
