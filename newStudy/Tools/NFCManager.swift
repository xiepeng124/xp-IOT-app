//
//  NFCManager.swift
//  studyCoreBluetooth
//
//  Created by 谢鹏 on 2026/4/9.
//

import Foundation
import CoreNFC

class NFCManager: NSObject {
    
    var session: NFCNDEFReaderSession?
    
    // 回调闭包，用于将结果传回 UI
    var onResult: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    func startScanning() {
        // 1. 必须先检查硬件可用性
//        guard NFCNDEFReaderSession.readingAvailable else {
//            onError?("当前设备不支持 NFC 扫描")
//            return
//        }
        
        // 2. 初始化 Session
        // 注意：queue 为 nil 表示在子线程回调，invalidateAfterFirstRead 设为 true 通常更符合单次读取场景
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "请将手机顶部靠近 NFC 标签"
        session?.begin()
    }
}

extension NFCManager: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // 错误处理（用户取消或系统错误）
        let errorDesc = error.localizedDescription
        print("NFC 扫描失效：\(errorDesc)")
        
        // 过滤用户手动取消的情况
        if let nfcError = error as? NFCReaderError, nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async {
                self.onError?(errorDesc)
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var resultString = ""
        
        for message in messages {
            for record in message.records {
                // 3. 增强数据解析逻辑
                if let payloadString = String(data: record.payload, encoding: .utf8) {
                    resultString += payloadString
                }
            }
        }
        
        print("解析到的 NFC 内容: \(resultString)")
        
        // 回到主线程更新 UI
        DispatchQueue.main.async {
            self.onResult?(resultString)
        }
    }
}
