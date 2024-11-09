//
//  RingProgressView.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/31.
//

import UIKit
import QuartzCore

class ProgressTheme: NSObject {
    
    var tintColor: UIColor = .systemBlue
    var backgroundColor: UIColor = .init(white: 0.9, alpha: 1)
    
    var lineWidth: CGFloat = 1
    var opacity: CGFloat = 1
    var font: UIFont = .systemFont(ofSize: 18)
    
    var textAtts: [NSAttributedString.Key : Any] = .init()
    var textParagraph = NSMutableParagraphStyle()
    
    override init() {
        super.init()
        
        reloadTextAttributes()
    }
    
    func reloadTextAttributes() {
        textParagraph.lineBreakMode = .byWordWrapping
        let attributes = [NSAttributedString.Key.font: font,
                          .foregroundColor : tintColor,
                          .paragraphStyle : textParagraph]
        textAtts = attributes
    }
}



class CircleProgressView: UIView {

    var progress: CGFloat = 0.0
    var style = ProgressTheme()
    
    var text: String = " " {
        didSet {
            if self.text != oldValue {
                updateText(self.text)
            }
        }
    }
    var showText: Bool = true {
        didSet {
            if self.showText != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var contentInsets: UIEdgeInsets = .zero
    var textContentInsets: UIEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
    
    private var foregroundLayer = CALayer()
    private var progressLayer = CAShapeLayer()
    private var backgroundLayer = CAShapeLayer()
    
    
    private var textLayer: CATextLayer?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialization()
    }
    
    func initialization() {
        self.contentMode = .redraw
        self.progressLayer.strokeEnd = 0
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        backgroundLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()
        textLayer?.removeFromSuperlayer()
        
        let backgroundColor = style.backgroundColor
        let tintColor = style.tintColor
        let lineWidth = style.lineWidth
        let opacity = style.opacity
        
        let contentRect = rect.inset(by: contentInsets)
        let contentRadiu = CGFloat.minimum(contentRect.width, contentRect.height)
        let center = CGPoint(x: contentInsets.left + lineWidth, y: contentInsets.top + lineWidth)
        // 圆环蒙版
        let ringPath = UIBezierPath(arcCenter: center,
                                    radius: (contentRadiu - style.lineWidth) / 2.0,
                                    startAngle: -0.5 * Double.pi, endAngle: 1.5 * Double.pi,
                                    clockwise: true)
        ringPath.lineWidth = style.lineWidth
        backgroundLayer.setFrame(contentRect,strokeColor: backgroundColor, opacity: opacity, lineWidth: lineWidth)
        backgroundLayer.path = ringPath.cgPath
        layer.addSublayer(backgroundLayer)
        
        progressLayer.setFrame(contentRect, fillColor: .clear, strokeColor: tintColor, opacity: opacity, lineWidth: lineWidth)
        progressLayer.lineCap = .round
        progressLayer.path = ringPath.cgPath
        layer.addSublayer(progressLayer)
        
        
        if showText || textLayer == nil {
            textLayer = .init()
            textLayer?.contentsScale = UIScreen.main.scale
            textLayer?.alignmentMode = .center
            textLayer?.truncationMode = .middle
            textLayer?.font = style.font
            textLayer?.alignmentMode = .center
            textLayer?.foregroundColor = style.tintColor.cgColor
            textLayer?.truncationMode = .middle
            textLayer?.isWrapped = true
            textLayer?.setNeedsDisplay()
            layer.addSublayer(textLayer!)
            
            updateText(text)
        }
    }
    
    func updateText(_ text: String) {
        if showText {
            
            var textRect = frame.inset(by: contentInsets).inset(by: textContentInsets)
            let size = NSString(string: text).boundingRect(with: textRect.size,
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: style.textAtts,
                                                           context: nil).size
            textRect = CGRectMake(frame.size.width / 2.0 - size.width / 2.0,
                                  frame.size.height / 2.0 - size.height / 2.0,
                                  size.width,
                                  size.height)
            
            style.reloadTextAttributes()
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            textLayer?.string = NSAttributedString(string: text, attributes: style.textAtts)
            textLayer?.frame = textRect
            textLayer?.layoutIfNeeded()
            CATransaction.commit()
        }
    }
    
    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = progress
        
        progressLayer.strokeColor = style.tintColor.cgColor
        
        guard animated else {
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            progressLayer.strokeEnd = progress
            CATransaction.commit()
            return
        }
        
        CATransaction.transaction {
            self.progressLayer.strokeEnd = progress
        }
    }
}

extension CAShapeLayer {
    func setFrame(_ frame: CGRect, fillColor: UIColor? = nil, strokeColor: UIColor? = nil, opacity: CGFloat = 1, lineWidth: CGFloat = 1) {
        self.frame = frame
        self.fillColor = fillColor?.cgColor
        self.strokeColor = strokeColor?.cgColor
        self.opacity = Float(opacity)
        self.lineWidth = lineWidth
    }
}

extension CATransaction {
    static func transaction(_ timingFunction: CAMediaTimingFunction = .init(name: .easeInEaseOut),
                            disableActions: Bool = false,
                            duration: CGFloat = 1.0,
                            animationAction: () -> Void)
    {
        begin()
        setDisableActions(false)
        setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        setAnimationDuration(1)
        animationAction()
        commit()
    }
}
