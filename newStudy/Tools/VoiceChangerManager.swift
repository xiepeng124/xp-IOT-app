
import Foundation
import AVFoundation

/// 录音与变声管理器
class VoiceChangerManager: NSObject {
    
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timePitchNode: AVAudioUnitTimePitch?
    
    private var recordedFileURL: URL?
    var isRecording = false
    
    // 变声参数: pitch (音高), rate (速率)
    var pitch: Float = 1.0 {
        didSet {
            print("set - pitch ....")
            timePitchNode?.pitch = pitch * 100 // AVAudioUnitTimePitch 单位是 cents
        }
    }
    
    var rate: Float = 1 {
        didSet {
            timePitchNode?.rate = rate
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recording Functions
    func startRecording() -> Bool {
        guard !isRecording else { return false }
        
        // 1. 准备录音文件路径
        let fileName = "recorded_voice.m4a"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        recordedFileURL = fileURL
        
        // 2. 配置录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                print("Recording started")
            }
            return success
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            return false
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        audioRecorder?.stop()
        isRecording = false
        print("Recording stopped. File saved at: \(recordedFileURL?.absoluteString ?? "unknown")")
    }
    
    // MARK: - Playback with Voice Change
    func playWithVoiceChange(completion: @escaping (Bool) -> Void) {
        guard let url = recordedFileURL, FileManager.default.fileExists(atPath: url.path) else {
            completion(false)
            return
        }
        
        // 停止之前的播放
        stopPlaying()
        
        do {
            // 初始化音频引擎
            audioEngine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            let timePitchNode = AVAudioUnitTimePitch()
            let distortionUnit = AVAudioUnitDistortion()
            distortionUnit.loadFactoryPreset(.speechGoldenPi)
            distortionUnit.wetDryMix = 50
            
            // 连接节点: Player -> TimePitch -> Output
            audioEngine?.attach(playerNode)
            audioEngine?.attach(timePitchNode)
            audioEngine?.attach(distortionUnit)
            audioEngine?.connect(playerNode, to: distortionUnit, format: nil)
            audioEngine?.connect(distortionUnit, to: audioEngine!.outputNode, format: nil)
            
            // 加载音频文件
            let file = try AVAudioFile(forReading: url)
            playerNode.scheduleFile(file, at: nil)
            
            // 应用变声参数
            timePitchNode.pitch = 1200
            timePitchNode.rate = self.rate
            
            self.playerNode = playerNode
            self.timePitchNode = timePitchNode
            
            // 启动引擎并播放
            do {
                try audioEngine?.start()
            } catch {
                print("AVAudioEngine 启动失败: \(error.localizedDescription)")
            }
            playerNode.play()
            
            // 监听播放结束
           
//            playerNode.installTap(onBus: 0, bufferSize: 1024, format: file.processingFormat) { buffer, time in
//                // 简单的播放状态检测，实际项目中建议使用更精确的回调
//            }
            
            // 由于 AVAudioPlayerNode 没有直接的 completion block，这里简单模拟
            // 实际开发中可以通过计算时长或使用 AVAudioPlayer 的 delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(file.length) / Double(file.fileFormat.sampleRate)) {
                completion(true)
            }
            
        } catch {
            print("Failed to play with voice change: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func stopPlaying() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        timePitchNode = nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension VoiceChangerManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully")
        } else {
            print("Recording failed")
        }
        isRecording = false
    }
}
