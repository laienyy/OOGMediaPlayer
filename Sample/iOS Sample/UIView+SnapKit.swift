//
//  UIView+SnapKit.swift
//  iOS Sample
//
//  Created by YiYuan on 2024/10/30.
//

import UIKit
import SnapKit

extension UIView {
    func addSubviews(_ subviews: UIView...) {
        subviews.forEach({ addSubview($0) })
    }
    
    func addSubview(_ subView: UIView, makeConstraints closure: (_ make: ConstraintMaker) -> Void) {
        addSubview(subView)
        subView.snp.makeConstraints(closure)
    }
}
