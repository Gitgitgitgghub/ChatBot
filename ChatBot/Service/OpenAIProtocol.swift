//
//  OpenAIProtocol.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/12.
//

import Foundation
import Combine
import OpenAI
import UIKit

protocol OpenAIProtocol: ImageFileHandler {
    
    //var openAI: OpenAI {  get }
    
    func chatQuery(message: String) -> AnyPublisher<ChatMessage?, Error>
    
    func createImage(prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
    func editImage(info: [UIImagePickerController.InfoKey : Any], prompt: String, size: ImagesQuery.Size) -> AnyPublisher<ImagesResult, Error>
    
}
