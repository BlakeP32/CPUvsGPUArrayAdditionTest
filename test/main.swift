import MetalKit

var count: Int = 1000000
var arr1 = getRandArr(count: count)
var arr2 = getRandArr(count: count)

cpuAdd(arr1: arr1, arr2: arr2, count: count)
gpuAdd(arr1: arr1, arr2: arr2, count: count)

func cpuAdd(arr1: [Float], arr2: [Float], count: Int){
    print("cpu:")
    let start = CFAbsoluteTimeGetCurrent()
    var res = [Float].init(repeating: 0.0, count: count)
    for i in 0..<count {
        res[i] = arr1[i] + arr2[i]
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    for i in 0..<3{
        print("\(arr1[i]) + \(arr2[i]) = \(res[i])")
    }
    print("Time Elapsed: \(String(format: "%.05f", elapsed))")
    print()
}

func gpuAdd(arr1: [Float], arr2: [Float], count: Int) {
    print("GPU:")
    let start = CFAbsoluteTimeGetCurrent()
    
    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("Failed to create Metal device.")
    }

    guard let commandQueue = device.makeCommandQueue() else {
        fatalError("Failed to create command queue.")
    }

    guard let gpuFunctionLibrary = device.makeDefaultLibrary() else {
        fatalError("Failed to create GPU function library.")
    }

    guard let additionGPUFunction = gpuFunctionLibrary.makeFunction(name: "additon_compute_func") else {
        fatalError("Failed to find the addition GPU function.")
    }

    let additionComputePipelineState: MTLComputePipelineState
    do {
        additionComputePipelineState = try device.makeComputePipelineState(function: additionGPUFunction)
    } catch {
        fatalError("Failed to create compute pipeline state: \(error).")
    }

    guard let arr1Buff = device.makeBuffer(bytes: arr1, length: MemoryLayout<Float>.size * count, options: .storageModeShared) else {
        fatalError("Failed to create buffer for arr1.")
    }

    guard let arr2Buff = device.makeBuffer(bytes: arr2, length: MemoryLayout<Float>.size * count, options: .storageModeShared) else {
        fatalError("Failed to create buffer for arr2.")
    }

    guard let resultBuff = device.makeBuffer(length: MemoryLayout<Float>.size * count, options: .storageModeShared) else {
        fatalError("Failed to create buffer for result.")
    }

    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        fatalError("Failed to create command buffer.")
    }

    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
        fatalError("Failed to create command encoder.")
    }
    
    commandEncoder.setComputePipelineState(additionComputePipelineState)
    commandEncoder.setBuffer(arr1Buff, offset: 0, index: 0)
    commandEncoder.setBuffer(arr2Buff, offset: 0, index: 1)
    commandEncoder.setBuffer(resultBuff, offset: 0, index: 2)

    let threadsPerGrid = MTLSize(width: count, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = additionComputePipelineState.maxTotalThreadsPerThreadgroup
    let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
    commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    var resultBufferPointer = resultBuff.contents().bindMemory(to: Float.self, capacity: MemoryLayout<Float>.size * count)
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(Float(resultBufferPointer.pointee) as Any)")
        resultBufferPointer = resultBufferPointer.advanced(by: 1)
    }
    print("Time Elapsed: \(String(format: "%.05f", elapsed))")
    print()
}


func getRandArr(count: Int)->[Float]{
    var res = [Float].init(repeating: 0.0, count: count)
    for i in 0..<count {
        res[i] = Float(arc4random_uniform(10))
    }
    return res
}

