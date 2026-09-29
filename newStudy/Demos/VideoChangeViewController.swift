//
//  VideoChangeViewController.swift
//  newStudy
//
//  Created by xp on 2026/8/14.
//


import UIKit
import AVFoundation

class AudioChangeViewController: UIViewController {
    
    private let manager = VoiceChangerManager()
    
    private let recordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("开始录音", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let playButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("播放 (原声)", for: .normal)
        btn.backgroundColor = .systemGreen
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let pitchSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 100
        slider.value = 1.0
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let pitchLabel: UILabel = {
        let label = UILabel()
        label.text = "音高: 1.0x"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupActions()
        checkPermissions()
    }
    
    private func setupUI() {
        view.addSubview(recordButton)
        view.addSubview(playButton)
        view.addSubview(pitchSlider)
        view.addSubview(pitchLabel)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            recordButton.widthAnchor.constraint(equalToConstant: 150),
            recordButton.heightAnchor.constraint(equalToConstant: 50),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            pitchSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pitchSlider.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 40),
            pitchSlider.widthAnchor.constraint(equalToConstant: 250),
            
            pitchLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pitchLabel.topAnchor.constraint(equalTo: pitchSlider.bottomAnchor, constant: 10)
        ])
    }
    
    private func setupActions() {
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        pitchSlider.addTarget(self, action: #selector(pitchChanged), for: .valueChanged)
    }
    
    private func checkPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "权限拒绝", message: "请允许麦克风权限以使用录音功能", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func recordTapped() {
        if manager.isRecording {
            manager.stopRecording()
            recordButton.setTitle("开始录音", for: .normal)
            recordButton.backgroundColor = .systemBlue
        } else {
            let success = manager.startRecording()
            if success {
                recordButton.setTitle("停止录音", for: .normal)
                recordButton.backgroundColor = .systemRed
            }
        }
    }
    
    @objc private func playTapped() {
        // 这里演示变声播放，若需原声播放可单独实现 AVAudioPlayer
        manager.playWithVoiceChange { success in
            if success {
                print("Playback finished")
            }
        }
    }
    
    @objc private func pitchChanged() {
        let value = pitchSlider.value
        manager.pitch = value
        pitchLabel.text = String(format: "音高: %.1fx", value)
    }
}
