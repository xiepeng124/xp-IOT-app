//
//  BluetoothViewController.swift
//  newStudy
//
//  Created by ma c on 2026/4/16.
//

import UIKit
import CoreBluetooth
class BluetoothViewController: UIViewController {
    private var centralManager: CBCentralManager!
    private var ledPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    // UI Elements
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "初始化中..."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送测试数据", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 1. 初始化中央管理器，delegate 设为 self
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "蓝牙调试"
        
        view.addSubview(statusLabel)
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sendButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 200),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        sendButton.addTarget(self, action: #selector(sendTestData), for: .touchUpInside)
    }
    
    @objc private func sendTestData() {
        guard let char = writeCharacteristic, let peripheral = ledPeripheral else { return }
        let dataString = "CMD:TEXT,Hello,iOS"
        if let data = dataString.data(using: .utf8) {
            // 根据特征属性选择写入类型
            let writeType: CBCharacteristicWriteType = char.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
            peripheral.writeValue(data, for: char, type: writeType)
            updateStatus("已发送数据: \(dataString)")
        }
    }
    
    private func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = text
            print(text)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothViewController: CBCentralManagerDelegate {
    
    // 2. 检查蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            updateStatus("蓝牙已开启，正在搜索设备...")
            startScanning()
        case .poweredOff:
            updateStatus("蓝牙已关闭，请在设置中开启")
        case .unauthorized:
            updateStatus("未授权蓝牙访问，请在设置中授权")
        case .unsupported:
            updateStatus("该设备不支持蓝牙低功耗 (BLE)")
        default:
            updateStatus("蓝牙状态异常: \(central.state.rawValue)")
        }
    }
    
    // 3. 发现外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 为了演示，这里一旦发现指定服务的设备就停止扫描并尝试连接
        updateStatus("发现设备: \(peripheral.name ?? "未知设备") (RSSI: \(RSSI))")
        // 保存引用并停止扫描
//        self.ledPeripheral = peripheral
//        centralManager.stopScan()
//        
//        // 尝试连接
//        updateStatus("正在连接: \(peripheral.name ?? "未知设备")...")
//        centralManager.connect(peripheral, options: nil)
    }
    
    // 4. 连接成功 (修复：原代码写成了 didDisconnectPeripheral)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        updateStatus("连接成功: \(peripheral.name ?? "设备")\n正在发现服务...")
        
        peripheral.delegate = self
        // 发现指定的服务
        peripheral.discoverServices([CBUUID(string: "FFE0")])
    }
    
    // 5. 连接失败处理
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        updateStatus("连接失败: \(error?.localizedDescription ?? "未知错误")")
    }
    
    // 6. 断开连接处理
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateStatus("蓝牙已断开")
        sendButton.isHidden = true
        writeCharacteristic = nil
        // 可以根据需要在这里尝试重新扫描
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothViewController: CBPeripheralDelegate {
    
    // 7. 发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            updateStatus("服务发现失败: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            updateStatus("发现服务: \(service.uuid)\n正在发现特征...")
            // 发现该服务下的特征
            peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
        }
    }
    
    // 8. 发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            updateStatus("特征发现失败: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == CBUUID(string: "FFE1") {
                self.writeCharacteristic = characteristic
                updateStatus("连接就绪，可以发送数据")
                
                // 显示发送按钮
                DispatchQueue.main.async {
                    self.sendButton.isHidden = false
                }
                
                // 订阅该特征，以便接收设备返回的数据
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    // 9. 接收到设备数据
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("数据读取失败: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let response = String(data: data, encoding: .utf8) {
            updateStatus("收到设备回复: \(response)")
        }
    }
}

extension BluetoothViewController {
    private func startScanning() {
        // 配置指定服务 UUID，如果想扫描所有设备，这里传 nil
        let servicesToScan = [
            CBUUID(string: "FFE0"),
            CBUUID(string: "180D")
        ]
        // 配置扫描选项，AllowDuplicatesKey 为 false 表示不重复扫描同一设备
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        centralManager.scanForPeripherals(withServices: nil, options: options)
    }
}
