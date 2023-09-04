//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension String {
    
    var unescaped: String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.dropFirst().dropLast()
            let description = String(descriptionCharacters)
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }
    
    /// A collection of all the words in the string by separating out any punctuation and spaces.
    var words: [String] {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
    
    /// Returns a lowercased copy of the string with punctuation removed and spaces replaced
    /// by a single hyphen, e.g., "the-quick-brown-fox-jumps-over-the-lazy-dog".
    ///
    /// *Lower kebab case* (or, illustratively, *kebab-case*) is also known as *spinal case*,
    /// *param case*, *Lisp case*, and *dash case*.
    func lowerKebabCased() -> String {
        return self.words.map({ $0.lowercased() }).joined(separator: "-")
    }
    
    /// Returns an uppercased copy of the string with punctuation removed and spaces replaced
    /// by a single hyphen, e.g., "THE-QUICK-BROWN-FOX-JUMPS-OVER-THE-LAZY-DOG".
    ///
    /// *Upper kebab case* (or, illustratively, *KEBAB-CASE*) is also known as *train case*.
    func upperKebabCased() -> String {
        return self.words.map({ $0.uppercased() }).joined(separator: "-")
    }
    
    /// Returns a copy of the string with punctuation removed and spaces replaced by a single
    /// hyphen, e.g., "The-quick-brown-fox-jumps-over-the-lazy-dog". Upper and lower casing
    /// is maintained from the original string.
    func mixedKebabCased() -> String {
        return self.words.joined(separator: "-")
    }
    
    func contains(_ strings: [String]) -> Bool {
        strings.contains { contains($0) }
    }
    
}
