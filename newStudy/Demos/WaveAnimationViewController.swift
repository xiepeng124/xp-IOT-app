//
//  WaveAnimationViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

class WaveAnimationViewController: UIViewController {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 100
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let waveView1 = TKWaveView()
    private let waveView2 = TKWaveView()
    
    private var isAnimating = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "三角函数水波动画"
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        
        waveView1.waveColor = .systemBlue.withAlphaComponent(0.5)
        waveView1.waveSpeed = 0.05
        waveView1.waveAmplitude = 12
        waveView1.waveCycle = 1.2
        waveView1.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(waveView1)
        
        waveView2.waveColor = .systemCyan.withAlphaComponent(0.5)
        waveView2.waveSpeed = 0.08
        waveView2.waveAmplitude = 8
        waveView2.waveCycle = 1.0
        waveView2.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(waveView2)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            waveView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            waveView1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            waveView1.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            waveView1.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            
            waveView2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            waveView2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            waveView2.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            waveView2.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        
        let label = UILabel()
        label.text = "y = A * sin(ωx + φ)"
        label.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 40),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimations()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAnimations()
    }
    
    private func startAnimations() {
        guard !isAnimating else { return }
        isAnimating = true
        waveView1.start()
        waveView2.start()
    }
    
    private func stopAnimations() {
        isAnimating = false
        waveView1.stop()
        waveView2.stop()
    }
    
    deinit {
        stopAnimations()
        print("WaveAnimationViewController deinit")
    }
}
