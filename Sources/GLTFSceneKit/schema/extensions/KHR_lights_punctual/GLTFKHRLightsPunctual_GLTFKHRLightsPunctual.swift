//
// https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_lights_punctual/README.md
//

import Foundation
import SceneKit

struct GLTFKHRLightsPunctual_GLTFKHRLightsPunctualExtension: GLTFCodable {
  struct GLTFLightsPunctual_GLTFLightsPunctual: Codable {
    struct LightsPunctual: Codable {
      enum LightType: String, Codable {
        case point
        case spot
        case directional
      }
      
      // TODO: spot cone angles
      
      let _color: [Float]?
      var color: [Float] {
        get { return self._color ?? [1, 1, 1] }
      }
      
      let _intensity: Float?
      var intensity: Float {
        get { return self._intensity ?? 0 }
      }
      
      let _range: Float?
      var range: Float {
        get { return self._range ?? 0 }
      }
      
      let type: LightType
      
      let name: String?
      
      private enum CodingKeys: String, CodingKey {
        case _color = "color"
        case _intensity = "intensity"
        case _range = "range"
        case type = "type"
        case name = "name"
      }
    }
    
    let lights: [LightsPunctual]?
    let light: Int?
    
    private enum CodingKeys: String, CodingKey {
      case lights
      case light
    }
  }
  let data: GLTFLightsPunctual_GLTFLightsPunctual?
  
  enum CodingKeys: String, CodingKey {
    case data = "KHR_lights_punctual"
  }
  
  func didLoad(by object: Any, unarchiver: GLTFUnarchiver) {
    // load lights for scene
    if let _ = object as? SCNScene, let lights = data?.lights {
      for i in 0..<lights.count {
        let light = lights[i]
        let scnLight = SCNLight()
        switch light.type {
        case .point:
          scnLight.type = .omni
        case .spot:
          scnLight.type = .spot
        case .directional:
          scnLight.type = .directional
        }
        
        // Blender exporter exports watts directly although the glTF side is supposed to be in candela
        // https://github.com/KhronosGroup/glTF-Blender-IO/issues/564
        // TODO: proper conversion as defined in spec

        // SceneKit lighting is in lumens, intensity is in candela
        scnLight.intensity = CGFloat(light.intensity / 12.57)
        
        // only should affect > 0
        if light.range > 0 {
          scnLight.attenuationEndDistance = CGFloat(light.range)
        }
        
        scnLight.color = UIColor(red: CGFloat(light.color[0]), green: CGFloat(light.color[1]), blue: CGFloat(light.color[2]), alpha: 1)
        
        unarchiver.lights[i] = scnLight
      }
      
      for i in 0..<unarchiver.lights.count {
        unarchiver.lightNodes[i]?.forEach {
          $0.light = unarchiver.lights[i]
        }
      }
    } else if let object = object as? SCNNode, let light = data?.light {
      // didLoad for scene extensions is called after didLoad for node extensions, so have to store this until later
      unarchiver.lightNodes[light] = (unarchiver.lightNodes[light] ?? []) + [object]
    }
  }
}


