//
//  AIManager.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import Foundation
import NaturalLanguage

class AIManager {
    static let shared = AIManager()
    
    // Simulates an AI improvement call (currently uses on-device NaturalLanguage)
    func improveText(_ text: String) async -> String {
        // Reduced delay to make it feel snappy but still "processing"
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        
        guard !text.isEmpty else { return "" }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        var improvedText = text
        
        // 1. Basic Capitalization and Punctuation (Naive approach for now)
        // Ensure first letter is capitalized
        if let first = improvedText.first {
            improvedText = String(first).uppercased() + improvedText.dropFirst()
        }
        
        // Ensure sentence ending punctuation if missing
        if let last = improvedText.last, !last.isPunctuation {
            improvedText.append(".")
        }
        
        // 2. Identify Proper Nouns (Names, Places, Orgs) and capitalize them
        // We reconstruct the string by replacing ranges. To avoid index shifts, we go backwards or use a mutable approach carefully.
        // Easier approach: Tokenize and reconstruct.
        
        var tokens: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, tokenRange in
            var token = String(text[tokenRange])
            
            if let tag = tag {
                switch tag {
                case .personalName, .placeName, .organizationName:
                    token = token.capitalized
                default:
                    break
                }
            } else {
                // Check if it's "i" (English specific, simple check)
                if token == "i" {
                    token = "I"
                }
            }
            
            tokens.append(token)
            return true
        }
        
        // Reconstructing from tokens is tricky because we lose original whitespace.
        // Better Strategy:
        // Iterate through tags and replace ranges in a mutable string copy, working effectively?
        // Actually, NLTagger's ranges are on the original string.
        
        var result = text
        // offset was unused
        
        // We will collect replacements first to avoid index invalidation issues if length DID change (it won't for simple capitalization).
        var replacements: [(Range<String.Index>, String)] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: []) { tag, tokenRange in
           let originalToken = text[tokenRange]
           var newToken = String(originalToken)
           
           if let tag = tag {
               if tag == .personalName || tag == .placeName || tag == .organizationName {
                   newToken = newToken.capitalized
               }
           }
           
            // Fix "i" -> "I"
            if newToken == "i" {
                newToken = "I"
            }
            
            // Fix sentence start? (Already roughly handled, but tagger helps with sentence boundaries too)
            
           if originalToken != newToken {
               replacements.append((tokenRange, newToken))
           }
           return true
        }
        
        // Apply replacements in reverse order to be safe (though length is same for cap, better practice)
        for (range, newString) in replacements.reversed() {
            result.replaceSubrange(range, with: newString)
        }
        
        // Final fix: Ensure first char is uppercased (again, just in case)
        if let first = result.first {
             result = String(first).uppercased() + result.dropFirst()
        }
         // Final fix: Ensure end punctuation
        if let last = result.last, !".!?".contains(last) {
            result.append(".")
        }
        
        return result
    }
}
