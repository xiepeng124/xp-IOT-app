//
//  LoadingViewController.swift
//  newStudy
//
//  Created by ma c on 2026/4/14.
//

import UIKit

// 创建一个类专门用于演示循环引用
class LeakObject {
    var name: String
    var closure: (() -> Void)?
    
    init(name: String) {
        self.name = name
        print("LeakObject init: \(name)")
    }
    
    deinit {
        print("LeakObject deinit - 这行不会打印!")
    }
}

// 全局数组用于强制持有内存，防止被释放
fileprivate var globalLeakedMemoryArray: [UnsafeMutableRawPointer] = []

class LoadingViewController: UIViewController {
    private var loadingView: TKLoadingView!
    
    // 强引用对象用于演示
    private var leakObject: LeakObject?
    private var timer: Timer?
    private var selfRetain: LoadingViewController? // 用于强制持有 self
    private var testData:String?
    private let controlButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始动画", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let leakButton1: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("方式1: 闭包循环", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    private let leakButton2: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("方式2: 内存未释放", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    private let leakButton3: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("方式3: Timer泄漏", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemPurple
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ 内存泄漏演示\n选择一种方式，然后返回上一页\n方式2在Leaks工具中会明确标红"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemYellow
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        loadingView = TKLoadingView(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        loadingView.center = view.center
        view.addSubview(loadingView)

        setupControlButton()
        setupLeakDemoButtons()
    }
    
    private func setupControlButton() {
        controlButton.frame = CGRect(x: (view.bounds.width - 120) / 2, y: view.bounds.height - 80, width: 120, height: 44)
        controlButton.addTarget(self, action: #selector(toggleAnimation), for: .touchUpInside)
        view.addSubview(controlButton)
    }
    
    private func setupLeakDemoButtons() {
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let buttonWidth: CGFloat = 110
        let spacing: CGFloat = 10
        let startX = (view.bounds.width - (buttonWidth * 3 + spacing * 2)) / 2
        let startY = view.bounds.height - 200
        
        leakButton1.frame = CGRect(x: startX, y: startY, width: buttonWidth, height: 44)
        leakButton1.addTarget(self, action: #selector(triggerLeakType1), for: .touchUpInside)
        view.addSubview(leakButton1)
        
        leakButton2.frame = CGRect(x: startX + buttonWidth + spacing, y: startY, width: buttonWidth, height: 44)
        leakButton2.addTarget(self, action: #selector(triggerLeakType2), for: .touchUpInside)
        view.addSubview(leakButton2)
        
        leakButton3.frame = CGRect(x: startX + (buttonWidth + spacing) * 2, y: startY, width: buttonWidth, height: 44)
        leakButton3.addTarget(self, action: #selector(triggerLeakType3), for: .touchUpInside)
        view.addSubview(leakButton3)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc private func toggleAnimation() {
        loadingView.isAnimating.toggle()
        
        if loadingView.isAnimating {
            controlButton.setTitle("停止动画", for: .normal)
            controlButton.backgroundColor = .systemRed.withAlphaComponent(0.8)
            loadingView.startDouyinAnimation()
        } else {
            controlButton.setTitle("开始动画", for: .normal)
            controlButton.backgroundColor = .darkGray
            loadingView.stopDouyinAnimation()
        }
    }
    
    // MARK: - 内存泄漏方式1: 闭包循环引用
    
    @objc private func triggerLeakType1() {
        leakButton1.isEnabled = false
        leakButton1.backgroundColor = .systemGray
        
        let obj = LeakObject(name: "循环引用对象")
        self.leakObject = obj
        
        // 强引用循环：obj 强引用闭包，闭包强引用 obj
        obj.closure = {
            self.testData = "rwtwe"
            print("闭包执行，引用了: \(obj.name)")
        }
        
        obj.closure?()
        print("✅ 方式1已触发: 闭包循环引用\n请返回上一页，使用 Debug Memory Graph 查看")
    }
    
    // MARK: - 内存泄漏方式2: 全局变量持有 + malloc 未释放
    
    @objc private func triggerLeakType2() {
        leakButton2.isEnabled = false
        leakButton2.backgroundColor = .systemGray
        
        // 1. 先触发循环引用，确保 self 不被释放
        selfRetain = self
        
        // 2. 直接分配 1MB 内存，不释放
        let size = 1024 * 1024 // 1MB
        if let memory = malloc(size) {
            memset(memory, 0xAA, size)
            // 3. 关键：放到全局数组里，强制持有，永不释放
            globalLeakedMemoryArray.append(memory)
            
            print("✅ 方式2已触发: 全局持有 malloc \(size) 字节\n请返回上一页，在 Leaks 工具中查看")
            print("💡 提示：deinit 不会被调用，内存永远不会释放！")
        }
    }
    
    // MARK: - 内存泄漏方式3: Timer强引用
    
    @objc private func triggerLeakType3() {
        leakButton3.isEnabled = false
        leakButton3.backgroundColor = .systemGray
        
        // Timer 强引用 self，self 强引用 Timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        
        print("✅ 方式3已触发: Timer强引用\n请返回上一页，控制台会持续打印")
    }
    
    @objc private func timerTick() {
        print("⏰ Timer 仍在运行 - ViewController 内存泄漏了!")
    }
    
    deinit {
        print("LoadingViewController deinit - 这行不会打印")
        timer?.invalidate()
        timer = nil
        
        // 注意：这里的 free 不会被调用，因为内存泄漏了
        // 即使调用了，globalLeakedMemoryArray 还持有
    }
}
