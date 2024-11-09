//
//  OOGSlider.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/30.
//

import UIKit

class OOGSlider: UISlider {

    var trackBarHeight: CGFloat = 2
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tap)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    public func setOog200SliderConfig() {
        trackBarHeight = 2
        setThumbImage(UIImage(named: "slider_round.png"), for: .normal)
    }
    
    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.trackRect(forBounds: bounds)
        rect.size.height = trackBarHeight
        return rect
    }

    @objc func tapAction(_ reocgnizer: UIGestureRecognizer) {
        switch reocgnizer.state {
        case .ended:
            let point = reocgnizer.location(in: self)
            let trackRect = trackRect(forBounds: bounds)
            let value = (point.x - trackRect.minX) / trackRect.width
            setValue(Float(value), animated: true)
            sendActions(for: .valueChanged)
        default:
            break
        }
        
        print(reocgnizer.state.rawValue.description)
    }
}
