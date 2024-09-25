//
//  AIAudioServiceProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/9/18.
//

import Foundation
import Combine

protocol AIAudioServiceProtocol: AnyObject where Self: AIServiceProtocol {
    
    func textToSpeech(text: String) -> AnyPublisher<Data?, Error>
    
    func speechToText(url: URL, detectEnglish: Bool) -> AnyPublisher<String, Error>
}
