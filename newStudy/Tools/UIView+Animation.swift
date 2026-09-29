//
//  UIView+Animation.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

extension UIView {
    
    /// 抖动动画 (用于输入错误提示)
    func shake(count: Float = 3, for duration: TimeInterval = 0.3, withTranslation translation: CGFloat = 5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = count
        animation.duration = duration / TimeInterval(animation.repeatCount)
        animation.values = [-translation, translation]
        animation.autoreverses = true
        layer.add(animation, forKey: "shake")
    }
    
    /// 呼吸灯动画 (用于强调按钮或状态)
    func breathing(duration: TimeInterval = 1.0) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.3
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "breathing")
    }
    
    /// 3D 翻转动画
    func flip(duration: TimeInterval = 0.5, direction: FlipDirection = .horizontal) {
        let transitionOptions: UIView.AnimationOptions = direction == .horizontal ? .transitionFlipFromRight : .transitionFlipFromTop
        UIView.transition(with: self, duration: duration, options: [transitionOptions, .showHideTransitionViews], animations: nil, completion: nil)
    }
    
    enum FlipDirection {
        case horizontal
        case vertical
    }
    
    /// 缩放弹出动画 (Spring 效果)
    func pop(duration: TimeInterval = 0.3) {
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
    
    /// 循环旋转动画
    func rotate(duration: TimeInterval = 2.0) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = duration
        rotation.isCumulative = true
        rotation.repeatCount = 3
        layer.add(rotation, forKey: "rotation")
    }
    
    /// 停止所有层级动画
    func stopAnimations() {
        layer.removeAllAnimations()
    }
}
