
import AVFoundation

/// PCM 音频播放器
/// 支持直接播放裸 PCM 数据流，需指定采样率、声道数和位深度
class PCMPlayer {
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat?
    
    init(sampleRate: Double = 44100.0, channels: UInt32 = 1, isFloat: Bool = false) {
        // 1. 配置音频格式
        // 注意：必须与传入的 PCM 数据格式严格一致，否则会出现噪音或静音
        let commonFormat = isFloat ? AVAudioCommonFormat.pcmFormatFloat32 : AVAudioCommonFormat.pcmFormatInt32
        self.audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels,
        )
        
        // 2. 初始化引擎节点
        engine.attach(playerNode)
        
        // 3. 连接节点：Player -> Main Mixer -> Output
        // format: nil 表示让引擎自动协商格式，但在播放裸 PCM 时，建议确保 buffer 格式与 engine 输入格式兼容
        if let format = audioFormat {
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        } else {
            engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        }
        
        // 4. 启动引擎
        do {
            try engine.start()
        } catch {
            print("AVAudioEngine 启动失败: \(error.localizedDescription)")
        }
    }
    
    /// 播放本地 PCM 文件
    /// - Parameter filePath: PCM 文件的绝对路径
    func playPCMFile(at filePath: String) {
        guard let url = URL(string: filePath) else {
            
            print("无效的文件路径")
            return
        }
        print("url = \(url)")
        do {
            // AVAudioFile 可以读取裸 PCM 文件，但需要我们在创建时提供正确的格式提示
            // 如果文件没有头信息，AVAudioFile 可能无法直接识别，此时建议使用 readData 方式
            let file = try AVAudioFile(forReading: url)
            
            // 如果文件格式与引擎格式不匹配，可能需要重采样或转换
            // 这里假设文件内容与初始化时的 format 匹配
            playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            playerNode.play()
            
        } catch {
            print("加载 PCM 文件失败: \(error.localizedDescription)")
            // 如果 AVAudioFile 失败，尝试以 Data 方式加载（见下方 playPCMData）
        }
    }
    
    /// 播放内存中的 PCM 数据
    /// - Parameters:
    ///   - data: 原始 PCM 字节数据
    ///   - sampleRate: 采样率
    ///   - channels: 声道数
    ///   - bitDepth: 位深度 (16 或 32)
    func playPCMData(_ data: Data, sampleRate: Double, channels: UInt32, bitDepth: Int) {
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels
        ) else {
            print("无法创建音频格式")
            return
        }
        
        // 计算帧数
        // 16-bit: 每个样本 2 字节; 32-bit float: 每个样本 4 字节
        let bytesPerFrame = Int(channels) * (bitDepth / 8)
        let frameCount = AVAudioFrameCount(data.count / bytesPerFrame)
        
        // 创建 PCM Buffer
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("无法创建 PCM Buffer")
            return
        }
        
        buffer.frameLength = frameCount
        
        // 将 Data 复制到 Buffer
        data.withUnsafeBytes { rawBufferPointer in
            guard let dst = buffer.int16ChannelData else { 
                // 如果是 float 格式，使用 floatChannelData
                if let dstFloat = buffer.floatChannelData {
                    let src = rawBufferPointer.bindMemory(to: Float.self)
                    for ch in 0..<Int(channels) {
                        memcpy(dstFloat[ch], src.baseAddress! + ch * Int(frameCount), Int(frameCount) * MemoryLayout<Float>.size)
                    }
                }
                return 
            }
            
            // 假设是 16-bit Int
            let src = rawBufferPointer.bindMemory(to: Int16.self)
            for ch in 0..<Int(channels) {
                memcpy(dst[ch], src.baseAddress! + ch * Int(frameCount), Int(frameCount) * MemoryLayout<Int16>.size)
            }
        }
        
        // 调度播放
        playerNode.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop, completionHandler: nil)
        playerNode.play()
    }
    
    /// 停止播放
    func stop() {
        playerNode.stop()
    }
    
    /// 暂停播放
    func pause() {
        playerNode.pause()
    }
}
