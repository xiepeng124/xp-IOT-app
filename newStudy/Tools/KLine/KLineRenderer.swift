
import Metal
import MetalKit
import simd
struct Vertex {
    var position: vector_float2 // x, y
    var color: vector_float4    // r, g, b, a
}


class KLineRenderer: NSObject, MTKViewDelegate {
    
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState
    
    // 新增：存储顶点数据的 Buffer
    private var vertexBuffer: MTLBuffer?
    
    init?(device: MTLDevice, metalView: MTKView) {
        self.device = device
        
        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        // 1. 创建渲染管线 (同前文)
        do {
            let library = try device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertexShader")
            let fragmentFunction = library?.makeFunction(name: "fragmentShader")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            
            let colorAttachment = pipelineDescriptor.colorAttachments
            colorAttachment[0].pixelFormat = metalView.colorPixelFormat
            
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Pipeline Error: \(error)")
            return nil
        }
        
        super.init()
    }
    
    // 新增：接收数据并创建 Buffer
    func updateData(with prices: [Float]) {
        guard !prices.isEmpty else { return }
        
        var vertices: [Vertex] = []
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let range = maxPrice - minPrice == 0 ? 1 : maxPrice - minPrice
        
        // 将价格数据转换为归一化的顶点坐标
        for (index, price) in prices.enumerated() {
            // X轴：根据索引归一化到 -1.0 ~ 1.0
            let x = Float(index) / Float(prices.count - 1) * 2.0 - 1.0
            // Y轴：根据价格归一化到 -1.0 ~ 1.0 (注意 Metal Y轴向上为正，通常需翻转)
            let normalizedPrice = (price - minPrice) / range
            let y = normalizedPrice * 2.0 - 1.0
            
            // 简单颜色：涨红跌绿模拟（这里简化为随机色或固定色）
            let color = vector_float4(1.0, 0.5, 0.0, 1.0) // 橙色
            
            vertices.append(Vertex(position: vector_float2(x, y), color: color))
        }
        
        // 创建 MTLBuffer
        let dataSize = vertices.count * MemoryLayout<Vertex>.stride
        self.vertexBuffer = device.makeBuffer(bytes: vertices, length: dataSize, options: [])
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        // 如果没有数据或 Buffer，直接返回
        guard let buffer = vertexBuffer,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        encoder.setRenderPipelineState(pipelineState)
        
        // 关键：将 Buffer 绑定到 Shader 的 index 0
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        
        // 绘制三角形带 (Triangle Strip) 或点 (Point)
        // 这里假设绘制连线，使用 .triangleStrip 或 .lineStrip
        let vertexCount = buffer.length / MemoryLayout<Vertex>.stride
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
