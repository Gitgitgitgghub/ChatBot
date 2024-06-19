//
//  LaunchViewController.swift
//  ChatBot
//
//  Created by 吳俊諺 on 2024/6/18.
//

import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        let animatedChatBotView = AnimatedChatBotView(frame: self.view.bounds)
        self.view.addSubview(animatedChatBotView)
        animatedChatBotView.startAnimation()
    }


}

class AnimatedChatBotView: UIView {

    private let text = "ChatBot"
    private var shapeLayers: [CAShapeLayer] = []
    private let letterSpacing: CGFloat = 3  // 设置字母间隔
    private let initialDelay: TimeInterval = 0.5  // 初始延迟时间
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        setupShapeLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .white
        setupShapeLayers()
    }
    
    private func setupShapeLayers() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50),
            .foregroundColor: UIColor.black
        ]
        let totalWidth = calculateTotalWidth(attributes: attributes)
        let totalHeight = (text as NSString).size(withAttributes: attributes).height
        let xOffset = (self.bounds.width - totalWidth) / 2
        let yOffset = (self.bounds.height - totalHeight) / 2
        var currentXOffset = xOffset
        for char in text {
            let charString = String(char)
            let charSize = (charString as NSString).size(withAttributes: attributes)
            let path = createBezierPath(for: charString, at: CGPoint(x: currentXOffset, y: yOffset), with: attributes)
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = UIColor.black.cgColor
            shapeLayer.fillColor = nil
            shapeLayer.lineWidth = 1.0
            shapeLayer.opacity = 0
            // 垂直翻转坐标系
            shapeLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
            shapeLayer.position = CGPoint(x: currentXOffset + charSize.width / 2, y: self.bounds.height / 2) // 字符的中心位置
            self.layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
            currentXOffset += charSize.width + letterSpacing
        }
    }

    private func calculateTotalWidth(attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let textSize = (text as NSString).size(withAttributes: attributes)
        let totalSpacing = letterSpacing * CGFloat(text.count - 1)
        return textSize.width + totalSpacing
    }
    
    private func createBezierPath(for text: String, at point: CGPoint, with attributes: [NSAttributedString.Key: Any]) -> UIBezierPath {
        let path = UIBezierPath()
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        for run in runs {
            let font = attributes[.font] as! CTFont
            let glyphCount = CTRunGetGlyphCount(run)
            
            for i in 0..<glyphCount {
                let range = CFRangeMake(i, 1)
                var glyph = CGGlyph()
                var position = CGPoint()
                CTRunGetGlyphs(run, range, &glyph)
                CTRunGetPositions(run, range, &position)
                
                let letterPath = CTFontCreatePathForGlyph(font, glyph, nil)!
                let transform = CGAffineTransform(translationX: point.x + position.x, y: point.y + position.y)
                let letterBezierPath = UIBezierPath(cgPath: letterPath)
                letterBezierPath.apply(transform)
                path.append(letterBezierPath)
            }
        }
        return path
    }
    
    func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            for (index, shapeLayer) in self.shapeLayers.enumerated() {
                let delay = Double(index) * 0.1  // 每个字母延迟0.1秒
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = 0
                animation.toValue = 1
                animation.duration = 0.5
                animation.beginTime = CACurrentMediaTime() + delay
                animation.fillMode = .forwards
                animation.isRemovedOnCompletion = false
                shapeLayer.add(animation, forKey: nil)
                
                let opacityAnimation = CABasicAnimation(keyPath: "opacity")
                opacityAnimation.fromValue = 0
                opacityAnimation.toValue = 1
                opacityAnimation.duration = 0.5
                opacityAnimation.beginTime = CACurrentMediaTime() + delay
                opacityAnimation.fillMode = .forwards
                opacityAnimation.isRemovedOnCompletion = false
                shapeLayer.add(opacityAnimation, forKey: nil)
            }
        }
    }
}




