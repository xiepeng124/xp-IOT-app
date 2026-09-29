//
//  MQTTDemoViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

class MQTTDemoViewController: UIViewController {
    
    private let mqttManager = MQTTManager.shared
    private var messages: [MQTTMessage] = []
    
    // UI Elements
    private let statusView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "未连接"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "输入要发布的消息..."
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("发布", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 5
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MQTT 消息调试"
        view.backgroundColor = .systemBackground
        setupUI()
        setupMQTT()
        
        // 模拟连接
        mqttManager.connect(host: "broker.emqx.io", port: 1883, clientID: "ios_client_\(Int.random(in: 0...1000))")
    }
    
    private func setupUI() {
        view.addSubview(statusView)
        statusView.addSubview(statusLabel)
        view.addSubview(tableView)
        
        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)
        bottomBar.addSubview(inputField)
        bottomBar.addSubview(sendButton)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            statusView.heightAnchor.constraint(equalToConstant: 40),
            
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 10),
            
            tableView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60),
            
            inputField.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 15),
            inputField.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            
            sendButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -15),
            sendButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
            sendButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        sendButton.addTarget(self, action: #selector(publishMessage), for: .touchUpInside)
    }
    
    private func setupMQTT() {
        mqttManager.onStatusChanged = { [weak self] status in
            DispatchQueue.main.async {
                self?.statusLabel.text = status
            }
        }
        
        mqttManager.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.insert(message, at: 0)
                self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
    }
    
    @objc private func publishMessage() {
        guard let text = inputField.text, !text.isEmpty else { return }
        mqttManager.publish(topic: "test/topic", message: text)
        inputField.text = ""
        inputField.resignFirstResponder()
    }
}

extension MQTTDemoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MessageCell")
        let msg = messages[indexPath.row]
        cell.textLabel?.text = "[\(msg.topic)]"
        cell.detailTextLabel?.text = msg.payload
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}
