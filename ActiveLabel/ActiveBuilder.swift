//
//  ActiveBuilder.swift
//  ActiveLabel
//
//  Created by Pol Quintana on 04/09/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

typealias ActiveFilterPredicate = ((String) -> Bool)

struct ActiveBuilder {
    
    static func createElements(_ type: ActiveType, from text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        switch type {
        case .mention, .hashtag:
            return createElementsIgnoringFirstCharacter(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .url:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(from: text, for: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        }
    }
    
    static func createURLElements(from attrString: NSMutableAttributedString, range: NSRange, maximumLenght: Int?) -> [ElementTuple] {
        let type = ActiveType.url
        let originalText = attrString.string
        let matches = RegexParser.getElements(from: originalText, with: type.pattern, range: range)
        var elements: [ElementTuple] = []
        
        for match in matches where match.range.length > 2 {
            let word = (originalText as NSString).substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            guard let maxLenght = maximumLenght , word.characters.count > maxLenght else {
                let range = maximumLenght == nil ? match.range : (attrString.string as NSString).range(of: word)
                let element = ActiveElement.create(with: type, text: word)
                elements.append((range, element, type))
                continue
            }
            
            let trimmedWord = word.trim(to: maxLenght)
            
            while true {
                let currentRange = (attrString.string as NSString).range(of: word)
                if currentRange.location == NSNotFound {
                    break
                } else {
                    attrString.replaceCharacters(in: currentRange, with: trimmedWord)
                }
                let newRange = (attrString.string as NSString).range(of: trimmedWord)
                let element = ActiveElement.url(original: word, trimmed: trimmedWord)
                elements.append((newRange, element, type))
            }
        }
        return elements
    }
    
    fileprivate static func createElements(from text: String,
                                           for type: ActiveType,
                                           range: NSRange,
                                           minLength: Int = 2,
                                           filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []
        
        for match in matches where match.range.length > minLength {
            let word = nsstring.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }
    
    fileprivate static func createElementsIgnoringFirstCharacter(from text: String,
                                                                 for type: ActiveType,
                                                                 range: NSRange,
                                                                 filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []
        
        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }
            
            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }
}
