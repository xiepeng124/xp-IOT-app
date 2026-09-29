//
//  KeyframeAnimationViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

class KeyframeAnimationViewController: UIViewController {
    
    private let animatedBall: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 15
        // 添加一点阴影增加立体感
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.5
        return view
    }()
    
    private let pathLayer = CAShapeLayer()
    private var timer:Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "复杂曲线动画"
        view.backgroundColor = .systemBackground
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
        setupUI()
    }
    
    private func setupUI() {
        // 绘制引导路径（虚线）
        pathLayer.strokeColor = UIColor.systemGray4.cgColor
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.lineWidth = 2
        pathLayer.lineDashPattern = [4, 4]
        view.layer.addSublayer(pathLayer)
        
        view.addSubview(animatedBall)
        
        let startBtn = UIButton(type: .system)
        startBtn.setTitle("开始曲线动画", for: .normal)
        startBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startBtn.addTarget(self, action: #selector(startAnimation), for: .touchUpInside)
        startBtn.frame = CGRect(x: (view.bounds.width - 150) / 2, y: view.bounds.height - 100, width: 150, height: 50)
        view.addSubview(startBtn)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePath()
    }
    
    private func updatePath() {
        let path = createComplexPath()
        pathLayer.path = path.cgPath
        animatedBall.center = CGPoint(x: 50, y: 200)
    }
    
    private func createComplexPath() -> UIBezierPath {
        let path = UIBezierPath()
        let width = view.bounds.width
        
        // 起点
        path.move(to: CGPoint(x: 50, y: 200))
        
        // 第一段：贝塞尔曲线
        path.addCurve(to: CGPoint(x: width - 50, y: 300),
                      controlPoint1: CGPoint(x: width/2, y: 0),
                      controlPoint2: CGPoint(x: width/2, y: 500))
        
        // 第二段：弧线返回
        path.addArc(withCenter: CGPoint(x: width/2, y: 450),
                    radius: 100,
                    startAngle: 0,
                    endAngle: .pi,
                    clockwise: true)
        
        // 第三段：S形曲线回到下方
        path.addQuadCurve(to: CGPoint(x: 50, y: 650),
                          controlPoint: CGPoint(x: width, y: 700))
        
        return path
    }

    @objc private func startAnimation() {
        let path = createComplexPath()
        
        // 1. 位移动画 (基于路径)
        let orbit = CAKeyframeAnimation(keyPath: "position")
        orbit.path = path.cgPath
        orbit.duration = 4.0
        orbit.calculationMode = .paced // 确保速度均匀
        orbit.fillMode = .forwards
        orbit.isRemovedOnCompletion = false
        
        // 2. 缩放动画 (随位移变化)
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [1.0, 1.5, 0.5, 1.2, 1.0]
        scale.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        scale.duration = 4.0
        
        // 3. 颜色变化
        let color = CAKeyframeAnimation(keyPath: "backgroundColor")
        color.values = [UIColor.systemRed.cgColor, 
                        UIColor.systemBlue.cgColor, 
                        UIColor.systemGreen.cgColor, 
                        UIColor.systemYellow.cgColor, 
                        UIColor.systemRed.cgColor]
        color.duration = 4.0
        
        // 组合动画
        let group = CAAnimationGroup()
        group.animations = [orbit, scale, color]
        group.duration = 4.0
//        group.repeatCount = .infinity
        
        animatedBall.layer.add(group, forKey: "complexOrbit")
    }
    @objc private func startTimer() {
        print("这是一个定时任务....\(self.animatedBall)")
        
        
    }
}
