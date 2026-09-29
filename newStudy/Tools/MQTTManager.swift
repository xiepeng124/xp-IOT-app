//
//  MQTTManager.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import Foundation

/// 自定义 MQTT 消息结构
struct MQTTMessage {
    let topic: String
    let payload: String
    let qos: Int
    let date: Date = Date()
}

/// MQTT 状态结构体
struct MQTTStatus {
    let connected: Bool
    let statusDescription: String
}

/// 模拟 MQTT 管理类 (因为 Pod 安装失败，我们先用原生实现或协议封装)
/// 在实际项目中，安装好 CocoaMQTT 后，此类应作为包装器
class MQTTManager: NSObject {
    
    static let shared = MQTTManager()
    
    // 回调闭包
    var onMessageReceived: ((MQTTMessage) -> Void)?
    var onStatusChanged: ((String) -> Void)?
    
    private var isConnected = false
    
    private override init() {
        super.init()
    }
    
    /// 连接到服务器
    func connect(host: String, port: UInt16, clientID: String) {
        onStatusChanged?("正在连接到 \(host):\(port)...")
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isConnected = true
            self.onStatusChanged?("连接成功 (模拟)")
            
            // 模拟收到一条欢迎消息
            let welcomeMsg = MQTTMessage(topic: "system/welcome", payload: "欢迎使用 MQTT 模拟服务", qos: 1)
            self.onMessageReceived?(welcomeMsg)
        }
    }
    
    /// 断开连接
    func disconnect() {
        isConnected = false
        onStatusChanged?("已断开连接")
    }
    
    /// 订阅主题
    func subscribe(topic: String) {
        guard isConnected else { return }
        onStatusChanged?("已订阅主题: \(topic)")
        
        // 模拟接收数据
        if topic == "test/topic" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                let msg = MQTTMessage(topic: topic, payload: "这是一条来自 \(topic) 的模拟数据", qos: 0)
                self.onMessageReceived?(msg)
            }
        }
    }
    
    /// 发布消息
    func publish(topic: String, message: String) {
        guard isConnected else { return }
        onStatusChanged?("正在发布到 \(topic)...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onStatusChanged?("消息发布成功")
            // 模拟自发自收 (Loopback)
            let loopMsg = MQTTMessage(topic: topic, payload: message, qos: 0)
            self.onMessageReceived?(loopMsg)
        }
    }
}
