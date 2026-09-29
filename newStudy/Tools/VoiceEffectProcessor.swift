//
//  VoiceEffectProcessor.swift
//  newStudy
//
//  Created by xp on 2026/8/14.
//

import AVFoundation

enum VoiceEffectType { case maleToFemale, robot }
class VoiceEffectProcessor {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()
    
    // 变声效果单元（按需初始化）
    private var pitchUnit: AVAudioUnitTimePitch?
    private var distortionUnit: AVAudioUnitDistortion?
    
    init() {
        // 基础信号链：输入 → 混音器 → 输出
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    }
    
    /// **启用男声变女声效果**（音高提升12半音）
    func enableMaleToFemaleEffect() {
        guard pitchUnit == nil else { return }
        
        pitchUnit = AVAudioUnitTimePitch()
        pitchUnit?.pitch = 1200  // **提升12个半音（1个八度）**
        pitchUnit?.rate = 1.0     // 保持原始语速
        
        engine.attach(pitchUnit!)
        engine.connect(mixer, to: pitchUnit!, format: nil)
        engine.connect(pitchUnit!, to: engine.mainMixerNode, format: nil)
    }
    
    /// **启用机器人音效**（失真+固定音高）
    func enableRobotEffect() {
        guard distortionUnit == nil else { return }
        
        distortionUnit = AVAudioUnitDistortion()
        distortionUnit?.loadFactoryPreset(.speechAlienChatter)
        distortionUnit?.wetDryMix = 80  // **湿音比例80%，突出机械感**
        
        engine.attach(distortionUnit!)
        engine.connect(mixer, to: distortionUnit!, format: nil)
        engine.connect(distortionUnit!, to: engine.mainMixerNode, format: nil)
    }
    
    /// **处理PCM缓冲区**（核心变声逻辑）
    func processBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        do {
            try engine.start()
            player.scheduleBuffer(buffer, completionCallbackType: .dataConsumed, completionHandler: nil)
            player.play()
            
            // 等待处理完成（实际项目需异步优化）
            Thread.sleep(forTimeInterval: 0.1)
            return engine.mainMixerNode.outputFormat(forBus: 0) == buffer.format ? buffer : nil
        } catch {
            print("变声处理失败: $error.localizedDescription)")
            return nil
        }
    }
}

