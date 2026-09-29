
import UIKit
import MetalKit

class MetalKLineView: MTKView {
    
    private var renderer: KLineRenderer?
    
    override init(frame: CGRect, device: MTLDevice?) {
        // 1. 获取默认 Metal 设备
        let metalDevice = device ?? MTLCreateSystemDefaultDevice()
        super.init(frame: frame, device: metalDevice)
        
        guard let device = self.device else {
            fatalError("Metal is not supported on this device")
        }
        
        // 2. 配置 MTKView
        self.colorPixelFormat = .bgra8Unorm
//        self.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0) // 深色背景
        self.framebufferOnly = true // 优化：如果不读取渲染结果，设为 true
        
        // 3. 初始化渲染器
        self.renderer = KLineRenderer(device: device, metalView: self)
        self.delegate = self.renderer
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 外部调用此方法更新数据
    func updateData(with prices: [Float]) {
        renderer?.updateData(with: prices)
    }
}
