//
//  TKLoadingView.swift
//  newStudy
//
//  Created by ma c on 2026/4/16.
//

import UIKit

class TKLoadingView: UIView {
    public var isAnimating = false
    private let leftCircle: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        view.backgroundColor = UIColor(red: 254/255, green: 44/255, blue: 85/255, alpha: 0.9) // 抖音红
        view.layer.cornerRadius = 12.5
        // 添加发光效果
        view.layer.shadowColor = view.backgroundColor?.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.6
        return view
    }()

    private let rightCircle: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        view.backgroundColor = UIColor(red: 0/255, green: 242/255, blue: 234/255, alpha: 0.9) // 抖音青
        view.layer.cornerRadius = 12.5
        // 添加发光效果
        view.layer.shadowColor = view.backgroundColor?.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.6
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        leftCircle.center = CGPoint(x: 15, y: 15)
        rightCircle.center = CGPoint(x: 45, y: 15)
        addSubview(leftCircle)
        addSubview(rightCircle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func startDouyinAnimation() {
        let duration: TimeInterval = 0.6
        
        // 第一次交换位置
        func animateCycle() {
            // 检查动画状态
            guard isAnimating else {
                // 重置视图位置到初始状态
                UIView.animate(withDuration: 0.3) {
                    self.leftCircle.center = CGPoint(x: 15, y: 15)
                    self.rightCircle.center = CGPoint(x: 45, y: 15)
                    self.leftCircle.transform = .identity
                    self.rightCircle.transform = .identity
                }
                return
            }
            
            // 将红球置于顶层
            bringSubviewToFront(leftCircle)
            
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
                self.leftCircle.center = CGPoint(x: 45, y: 15)
                self.rightCircle.center = CGPoint(x: 15, y: 15)
                
                self.leftCircle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.rightCircle.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { [weak self] _ in
                guard let self else { return }
                // 再次检查动画状态
                guard isAnimating else { return }
                
                // 第二次交换位置（返回）
                // 将青球置于顶层，模拟 3D 环绕效果
                bringSubviewToFront(rightCircle )
                
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
                    self.leftCircle.center = CGPoint(x: 15, y: 15)
                    self.rightCircle.center = CGPoint(x: 45, y: 15)
                    
                    self.leftCircle.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    self.rightCircle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }) { _ in
                    // 循环执行
                    animateCycle()
                }
            }
        }
        
        animateCycle()
    }
    public func stopDouyinAnimation() {
        UIView.animate(withDuration: 0.3) {
            self.leftCircle.center = CGPoint(x: 15, y: 15)
            self.rightCircle.center = CGPoint(x: 45, y: 15)
            self.leftCircle.transform = .identity
            self.rightCircle.transform = .identity
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
