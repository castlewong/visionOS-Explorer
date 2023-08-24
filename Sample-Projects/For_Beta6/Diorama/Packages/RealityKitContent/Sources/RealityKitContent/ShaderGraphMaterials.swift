/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on entity-containing methods to help when updating Shader Graph material parameters.
*/

import RealityKit

public extension Entity {

    var modelComponent: ModelComponent? {
        components[ModelComponent.self]
    }

    var shaderGraphMaterial: ShaderGraphMaterial? {
        modelComponent?.materials.first as? ShaderGraphMaterial
    }

    func update(shaderGraphMaterial oldMaterial: ShaderGraphMaterial,
                _ handler: (inout ShaderGraphMaterial) throws -> Void) rethrows {
        var material = oldMaterial
        try handler(&material)

        if var component = modelComponent {
            component.materials = [material]
            components.set(component)
        }
    }
    
    var parameterNames: [String]? {
        shaderGraphMaterial?.parameterNames
    }
    
    func hasMaterialParameter(named: String) -> Bool {
        parameterNames?.contains(where: { $0 == named }) ?? false
    }
}
