//
//  WordModel.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/8.
//

import Foundation


import Foundation

struct WordDefinition: Codable {
    let partOfSpeech: String
    var definition: String
    
    enum CodingKeys: String, CodingKey {
        case partOfSpeech = "part_of_speech"
        case definition
    }
}

struct WordEntry: Codable {
    let number: String?
    var word: String
    let definitions: [WordDefinition]
    var displayDefinitionString: String {
        return definitions.map { "(\($0.partOfSpeech)) \($0.definition.replacingOccurrences(of: " ", with: ""))" }.joined(separator: "\n")
    }
}

struct WordSentence: Codable, Equatable {
    let sentence: String
    let translation: String
}
