//
//  TKWaveView.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

// 使用弱引用代理来避免 CADisplayLink 的循环引用
private class WeakTarget {
    weak var target: TKWaveView?
    init(target: TKWaveView) {
        self.target = target
    }
    @objc func updateWave() {
        target?.updateWave()
    }
}

class TKWaveView: UIView {
    
    // MARK: - Properties
    var waveColor: UIColor = .systemBlue {
        didSet { waveLayer.fillColor = waveColor.cgColor }
    }
    
    var waveSpeed: CGFloat = 0.1
    var waveAmplitude: CGFloat = 10.0
    var waveCycle: CGFloat = 1.0
    
    private var offset: CGFloat = 0.0
    private let waveLayer = CAShapeLayer()
    private var displayLink: CADisplayLink?
    private weak var weakTarget: WeakTarget?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        waveLayer.fillColor = waveColor.cgColor
        layer.addSublayer(waveLayer)
    }
    
    // MARK: - Animation Control
    func start() {
        stop()
        let target = WeakTarget(target: self)
        self.weakTarget = target
        displayLink = CADisplayLink(target: target, selector: #selector(WeakTarget.updateWave))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        weakTarget = nil
    }
    
    @objc fileprivate func updateWave() {
        offset += waveSpeed
        
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        
        guard width > 0, height > 0 else { return }
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, to: width + 1, by: 1) {
            let angle = (2.0 * .pi / width) * x * waveCycle + offset
            let y = waveAmplitude * sin(angle) + height / 2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.close()
        
        waveLayer.path = path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        waveLayer.frame = bounds
    }
    
    deinit {
        stop()
        print("TKWaveView deinit")
    }
}
