//
//  NFCViewController.swift
//  studyCoreBluetooth
//
//  Created by 谢鹏 on 2026/4/9.
//

import UIKit

class NFCViewController: UIViewController {
    let nfcManager = NFCManager()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "等待扫描..."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNFCManager()
    }
    
    private func setupNFCManager() {
        nfcManager.onResult = { [weak self] text in
            self?.resultLabel.text = "扫描成功内容：\n\(text)"
            self?.resultLabel.textColor = .systemGreen
        }
        
        nfcManager.onError = { [weak self] error in
            let alert = UIAlertController(title: "NFC 错误", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的", style: .default))
            self?.present(alert, animated: true)
            self?.resultLabel.text = "扫描失败"
            self?.resultLabel.textColor = .systemRed
        }
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .systemBackground
        title = "NFC Scanner"
        
        let button = UIButton(type: .system)
        button.setTitle("开始扫描 NFC", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        view.addSubview(button)
        view.addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50),
            
            resultLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc func scanButtonTapped() {
        resultLabel.text = "正在准备扫描..."
        resultLabel.textColor = .secondaryLabel
        nfcManager.startScanning()
    }
}
