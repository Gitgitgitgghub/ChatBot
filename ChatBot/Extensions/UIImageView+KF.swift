//
//  UIImageView+KF.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/19.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {
    
    
    func loadImage(url: String?, placeHolder: UIImage? = nil, indicatorType: IndicatorType = .none, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        guard url != nil else { return }
        guard let url = URL(string: url!) else { return }
        kf.indicatorType = indicatorType
        kf.setImage(with: url, placeholder: placeHolder)
    }
    
}
