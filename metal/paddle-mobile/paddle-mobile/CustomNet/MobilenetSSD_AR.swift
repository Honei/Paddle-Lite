/* Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Foundation

public class MobileNet_ssd_AR: Net{
  @objc public override init(device: MTLDevice) {
    super.init(device: device)
    means = [103.94, 116.78, 123.68]
    scale = 1
    except = 2
    modelPath = Bundle.main.path(forResource: "ar_model", ofType: nil) ?! "model null"
    paramPath = Bundle.main.path(forResource: "ar_params", ofType: nil) ?! "para null"
    modelDir = ""
    preprocessKernel = MobilenetssdPreProccess.init(device: device)
    inputDim_ = Dim.init(inDim: [1, 160, 160, 3])
  }
  
  @objc override public init(device: MTLDevice,paramPointer: UnsafeMutableRawPointer, paramSize:Int, modePointer: UnsafeMutableRawPointer, modelSize: Int) {
    super.init(device:device,paramPointer:paramPointer,paramSize:paramSize,modePointer:modePointer,modelSize:modelSize)
    means = [103.94, 116.78, 123.68]
    scale = 1
    except = 2
    modelPath = ""
    paramPath = ""
    modelDir = ""
    preprocessKernel = MobilenetssdPreProccess.init(device: device)
    inputDim_ = Dim.init(inDim: [1, 160, 160, 3])
  }
  
  class MobilenetssdPreProccess: CusomKernel {
    init(device: MTLDevice) {
      let s = Shape.init(inWidth: 160, inHeight: 160, inChannel: 3)
      super.init(device: device, inFunctionName: "mobilent_ar_preprocess", outputDim: s, usePaddleMobileLib: false)
    }
  }
  
  override public func resultStr(res: ResultHolder) -> String {
    return " \(res.result[0])"
  }
  
  override func fetchResult(paddleMobileRes: GPUResultHolder) -> ResultHolder {
    guard let interRes = paddleMobileRes.intermediateResults else {
      fatalError(" need have inter result ")
    }
    
    guard let scores = interRes["Scores"], scores.count > 0, let score = scores[0] as?  FetchHolder else {
      fatalError(" need score ")
    }
    
    guard let bboxs = interRes["BBoxes"], bboxs.count > 0, let bbox = bboxs[0] as? FetchHolder else {
      fatalError()
    }
    
//    let startDate = Date.init()
    
//    print("scoreFormatArr: ")
//print((0..<score.capacity).map{ score.result[$0] }.strideArray())
//
//    print("bbox arr: ")
//
//    print((0..<bbox.capacity).map{ bbox.result[$0] }.strideArray())
    
    let nmsCompute = NMSCompute.init()
    nmsCompute.scoreThredshold = 0.25
    nmsCompute.nmsTopK = 100
    nmsCompute.keepTopK = 100
    nmsCompute.nmsEta = 1.0
    nmsCompute.nmsThreshold = 0.449999988
    nmsCompute.background_label = 0;
    nmsCompute.scoreDim = [NSNumber.init(value: score.dim[0]), NSNumber.init(value: score.dim[1]), NSNumber.init(value: score.dim[2])]
    nmsCompute.bboxDim = [NSNumber.init(value: bbox.dim[0]), NSNumber.init(value: bbox.dim[1]), NSNumber.init(value: bbox.dim[2])]
    guard let result = nmsCompute.compute(withScore: score.result, andBBoxs: bbox.result) else {
      fatalError( " result error " )
    }
    let resultHolder = ResultHolder.init(inResult: result.output, inCapacity: Int(result.outputSize))
//    for i in 0..<Int(result.outputSize) {
//
//      print("i \(i) : \(result.output[i])")
//    }
//    print(Date.init().timeIntervalSince(startDate))

//    print(resultHolder.result![0])
    return resultHolder
  }
  
  override func updateProgram(program: Program) {
//    for i in [56, 66, 76, 86, 93, 99] {
//      let opDesc = program.programDesc.blocks[0].ops[i]
//      let output = opDesc.outputs["Out"]!.first!
//      let v = program.scope[output]!
//      let originTexture = v as! Texture
//      originTexture.tensorDim = Dim.init(inDim: [originTexture.tensorDim[1] / 7, originTexture.tensorDim[0] * 7])
//      
//      originTexture.dim = Dim.init(inDim: [1, 1, originTexture.dim[3] / 7, originTexture.dim[2] * 7])
//      
//      originTexture.padToFourDim = Dim.init(inDim: [1, 1, originTexture.padToFourDim[3] / 7, originTexture.padToFourDim[2] * 7])
//      
//      program.scope[output] = originTexture
//      
//      if i == 99 {
//        opDesc.attrs["axis"] = 0
//      } else {
//        opDesc.attrs["shape"] = originTexture.tensorDim.dims.map { Int32($0) }
//      }
//    }
//    
//    for i in [58, 59, 88, 89, 95, 96, 68, 69, 78, 79] {
//      let opDesc = program.programDesc.blocks[0].ops[i]
//      let output = opDesc.outputs["Out"]!.first!
//      let v = program.scope[output]!
//      
//      
//      
//      let originTexture = v as! Texture
//      originTexture.tensorDim = Dim.init(inDim: [originTexture.tensorDim[1], originTexture.tensorDim[2]])
//      opDesc.attrs["shape"] = originTexture.tensorDim.dims.map { Int32($0) }
//    }
//    
//    for i in [60, 101, 90, 97, 70, 80] {
//      let opDesc = program.programDesc.blocks[0].ops[i]
//      let output = opDesc.outputs["Out"]!.first!
//      let v = program.scope[output]!
//      let originTexture = v as! Texture
//      originTexture.tensorDim = Dim.init(inDim: [originTexture.tensorDim[1], originTexture.tensorDim[2]])
//      opDesc.attrs["axis"] = (opDesc.attrs["axis"]! as! Int) - 1
//    }
//    
//    for i in [102] {
//      let opDesc = program.programDesc.blocks[0].ops[i]
//      for output in opDesc.outputs["Out"]! {
//        let v = program.scope[output]!
//        let originTexture = v as! Texture
//        originTexture.tensorDim = Dim.init(inDim: [originTexture.tensorDim[1], originTexture.tensorDim[2]])
//      }
//      opDesc.attrs["axis"] = (opDesc.attrs["axis"]! as! Int) - 1
//      print(" split axis \(opDesc.attrs["axis"])")
//    }
    // 99
  }
  
}
