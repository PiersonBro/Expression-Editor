//
//  HTMLStripper.swift
//  HTMLParser
//
//  Created by EandZ on 7/4/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import Foundation

class HTMLStripper: NSObject, XMLParserDelegate {
    let xmlParser: XMLParser
    var strings = [String]()
    
    init(html: String) {
        let newHTML = "<root>\(html.replacingOccurrences(of: "&", with: "&amp"))</root>"
        let data = newHTML.data(using: .utf8)!
        xmlParser = XMLParser(data: data)
        super.init()
        xmlParser.delegate = self
    }
    
    func start() -> [String] {
        xmlParser.parse()
        return strings
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        strings.append(string)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Try to fix issues here.
        print(parseError)
    }
}
