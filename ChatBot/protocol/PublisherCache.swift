//
//  PublisherCache.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/8/15.
//

import Foundation
import Combine

protocol PublisherCache: DataCacheProtocol {
    
    associatedtype DataType
    typealias valueType = AnyPublisher<DataType, Error>
    
}



