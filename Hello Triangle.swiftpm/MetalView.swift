import SwiftUI
import MetalKit

let shaderTxt = """
#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(
    const device packed_float3 *vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]) {

    return float4(vertex_array[vid], 1.0);
}

fragment half4 basic_fragment() {
    return half4(0.0);
}
"""

struct MetalView {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeMTKView(_ context: MetalView.Context) -> MTKView {
        let mtkView = MTKView()
        
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
                
        return mtkView
    }
    
    
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        let vertexData: [Float] = [
            0.0, 0.5, 0.0,
            -0.5, -0.5, 0.0,
            0.5, -0.5, 0.0,
        ]
        var vertexBuffer: MTLBuffer!
        
        init(_ parent: MetalView) {
            self.parent = parent
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            
            let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
            vertexBuffer = metalDevice.makeBuffer(bytes: vertexData, 
                                                  length: dataSize, 
                                                  options: .storageModePrivate)
            
            super.init()
            
            self.setupRenderPipelineState()
        }
        
        func setupRenderPipelineState() {
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            do {
                let lib = try device.makeLibrary(source: shaderTxt, options: .none)
                let vertexFn = lib.makeFunction(name: "basic_vertex")
                let fragFn = lib.makeFunction(name: "basic_fragment")
                
                let renderPipeDesc = MTLRenderPipelineDescriptor()
                renderPipeDesc.vertexFunction = vertexFn
                renderPipeDesc.fragmentFunction = fragFn
                renderPipeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                
                try pipelineState = device.makeRenderPipelineState(descriptor: renderPipeDesc)
            } catch {
                print("error render pipeline state library \(error)")
            }
        }

        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
             
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {
                print("nothing to draw")
                return
            }
            let cmdBuf = metalCommandQueue.makeCommandBuffer()
            
            let rpd = MTLRenderPassDescriptor()
            rpd.colorAttachments[0].texture = drawable.texture
            rpd.colorAttachments[0].loadAction = .clear
            rpd.colorAttachments[0].clearColor = MTLClearColor(
                red: 221.0/255.0, green: 160.0/255.0, blue: 221.0/255.0, alpha: 1.0
            )
                        
            let re = cmdBuf?.makeRenderCommandEncoder(descriptor: rpd)
            re?.setRenderPipelineState(pipelineState)
            re?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            re?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            re?.endEncoding()
            cmdBuf?.present(drawable)
            cmdBuf?.commit()
        }
    }
}

extension MetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        return makeMTKView(context)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
