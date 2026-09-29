//
//  GuideMaskView.swift
//  newStudy
//
//  Created by Assistant on 2026/5/3.
//

import UIKit

class GuideMaskView: UIView {
    
    struct GuideStep {
        let targetRect: CGRect
        let title: String
        let description: String
        let isRound: Bool
    }
    
    private var steps: [GuideStep] = []
    private var currentStepIndex: Int = 0
    
    private let maskLayer = CAShapeLayer()
    private let tipContainerView = UIView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    
    var onDismiss: (() -> Void)?
    
    init(steps: [GuideStep]) {
        super.init(frame: UIScreen.main.bounds)
        self.steps = steps
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.7).cgColor
        layer.addSublayer(maskLayer)
        
        tipContainerView.backgroundColor = .white
        tipContainerView.layer.cornerRadius = 12
        tipContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tipContainerView)
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .systemGray
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton.setTitle("下一步", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 6
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextStep), for: .touchUpInside)
        
        skipButton.setTitle("跳过指引", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 14)
        skipButton.setTitleColor(.systemGray, for: .normal)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(dismissGuide), for: .touchUpInside)
        
        tipContainerView.addSubview(titleLabel)
        tipContainerView.addSubview(descLabel)
        tipContainerView.addSubview(nextButton)
        tipContainerView.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            tipContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            tipContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            tipContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            titleLabel.topAnchor.constraint(equalTo: tipContainerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: tipContainerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: tipContainerView.trailingAnchor, constant: -20),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: tipContainerView.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: tipContainerView.trailingAnchor, constant: -20),
            
            nextButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: tipContainerView.trailingAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 80),
            nextButton.heightAnchor.constraint(equalToConstant: 36),
            nextButton.bottomAnchor.constraint(equalTo: tipContainerView.bottomAnchor, constant: -20),
            
            skipButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            skipButton.leadingAnchor.constraint(equalTo: tipContainerView.leadingAnchor, constant: 20)
        ])
    }
    
    func show(in view: UIView) {
        view.addSubview(self)
        updateStep()
    }
    
    private func updateStep() {
        guard currentStepIndex < steps.count else {
            dismissGuide()
            return
        }
        
        let step = steps[currentStepIndex]
        titleLabel.text = step.title
        descLabel.text = step.description
        
        if currentStepIndex == steps.count - 1 {
            nextButton.setTitle("知道了", for: .normal)
        } else {
            nextButton.setTitle("下一步", for: .normal)
        }
        
        updateMask(rect: step.targetRect, isRound: step.isRound)
    }
    
    private func updateMask(rect: CGRect, isRound: Bool) {
        let path = UIBezierPath(rect: bounds)
        let highlightPath: UIBezierPath
        
        if isRound {
            let radius = max(rect.width, rect.height) / 2 + 10
            highlightPath = UIBezierPath(roundedRect: rect.insetBy(dx: -10, dy: -10), cornerRadius: radius)
        } else {
            highlightPath = UIBezierPath(roundedRect: rect.insetBy(dx: -5, dy: -5), cornerRadius: 8)
        }
        
        path.append(highlightPath.reversing())
        maskLayer.path = path.cgPath
    }
    
    @objc private func nextStep() {
        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            UIView.animate(withDuration: 0.3) {
                self.updateStep()
                self.layoutIfNeeded()
            }
        } else {
            dismissGuide()
        }
    }
    
    @objc private func dismissGuide() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
}
