//
//  PCMPlayerViewController.swift
//  newStudy
//
//  Created by xp on 2026/8/13.
//


import UIKit
import AVFoundation

class PCMPlayerViewController: UIViewController {

    private var pcmPlayer: PCMPlayer?
    private let playButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // 设置音频会话类别，允许后台播放和混合其他音频
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error.localizedDescription)")
        }
    }
    
    private func setupUI() {
        playButton.setTitle("播放 PCM", for: .normal)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playAction), for: .touchUpInside)
        
        stopButton.setTitle("停止", for: .normal)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(stopAction), for: .touchUpInside)
        
        view.addSubview(playButton)
        view.addSubview(stopButton)
        
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50)
        ])
    }
    
    @objc private func playAction() {
        // 初始化播放器：44100Hz, 单声道, 16-bit
        // 实际项目中，sampleRate 和 channels 应与你的 PCM 源数据一致
        pcmPlayer = PCMPlayer(sampleRate: 44100.0, channels: 1, isFloat: false)
        
        // 示例：播放本地测试文件
        // 请确保项目中有一个名为 "test.pcm" 或 "test.wav" (裸PCM也可命名为wav但无头) 的文件
        if let path = Bundle.main.path(forResource: "test", ofType: "pcm") {
            pcmPlayer?.playPCMFile(at: path)
        } else {
            // 如果没有文件，生成一段简单的正弦波 PCM 数据进行测试
            let testData = generateTestPCMData()
            pcmPlayer?.playPCMData(testData, sampleRate: 44100.0, channels: 1, bitDepth: 16)
        }
    }
    
    @objc private func stopAction() {
        pcmPlayer?.stop()
    }
    
    // 生成 1 秒长的 440Hz 正弦波 PCM 数据 (16-bit)
    private func generateTestPCMData() -> Data {
        let sampleRate = 44100.0
        let duration = 4.0
        let frequency = 440.0
        let amplitude: Int16 = 16000
        
        let sampleCount = Int(sampleRate * duration)
        var data = Data(capacity: sampleCount * 2) // 16-bit = 2 bytes per sample
        
        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let value = sin(2.0 * .pi * frequency * time)
            let sample = Int16(value * Double(amplitude))
            
            // 小端序写入
            let bytes = withUnsafeBytes(of: sample.littleEndian) { Array($0) }
            data.append(contentsOf: bytes)
        }
        
        return data
    }
}

