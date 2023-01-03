/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system and component for drawing traces behind satellites.
*/

import Foundation
import RealityKit

/// Trace information for an entity.
struct TraceComponent: Component {
    var accumulatedTime: TimeInterval = 0
    var mesh: TraceMesh
    var isPaused: Bool = false

    weak var anchor: Entity?
    var model: ModelEntity?

    init(anchor: Entity, width: Float) {
        self.anchor = anchor
        self.mesh = TraceMesh(width: width)
    }
}

/// A system that draws a trace behind moving entities that have
/// a trace component.
struct TraceSystem: System {
    static let query = EntityQuery(where: .has(TraceComponent.self))

    init(scene: Scene) { }

    func update(context: SceneUpdateContext) {
        for satellite in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            var trace: TraceComponent = satellite.components[TraceComponent.self]!
            defer { satellite.components[TraceComponent.self] = trace }

            guard let anchor = trace.anchor else { return }

            trace.accumulatedTime += context.deltaTime
            if trace.isPaused || trace.accumulatedTime <= 0.025 { return }
            trace.accumulatedTime = 0

            // Store the satellite's current position in the anchor's
            // coordinate system.
            trace.mesh.addPosition(of: satellite, relativeTo: anchor)

            let contents = trace.mesh.meshContents

            // Update the existing trace mesh or create a new one.
            do {
                if let model = trace.model {
                    try model.model?.mesh.replace(with: contents)
                } else {
                    let model = try ModelEntity.makeTraceModel(with: contents)
                    model.name = "\(anchor.name)-trace"
                    trace.model = model
                    anchor.addChild(model)
                }
            } catch {
                print("Failed to create or update trace mesh.")
            }
        }
    }
}

struct TraceMesh {
    var positions: [SIMD3<Float>] = []
    var uvs: [SIMD2<Float>] = []
    var width: Float = 5
    static let maxIndexCount: UInt32 = 400
    static let triangleIndices = Self.generateIndices()

    init(width: Float) {
        self.width = width
    }
}

extension TraceMesh {
    mutating func addPosition(of entity: Entity, relativeTo referenceEntity: Entity) {
        let width = self.width / 1e5
        positions.append(entity.convert(position: entity.position - [0, width, 0],
                                        to: referenceEntity))
        positions.append(entity.convert(position: entity.position + [0, width, 0],
                                        to: referenceEntity))
        uvs.removeAll(keepingCapacity: true)
        var updatedPositions = [SIMD3<Float>]()
        let rowCount = positions.count
        
        _ = stride(from: 0, to: positions.endIndex, by: 2).map { row in
            let leftPosition = positions[row]
            let rightPosition = positions[row + 1]
            let fractionalValue = Float(row) / Float(rowCount)
           
            uvs.append([fractionalValue, 0])
            uvs.append([fractionalValue, 1])

            let center = (rightPosition + leftPosition) / 2
            let directionVector = simd_normalize(rightPosition - leftPosition)
            updatedPositions.append(center - (directionVector) * (fractionalValue * 0.004))
            updatedPositions.append(center + (directionVector) * (fractionalValue * 0.004))
        }
        positions = updatedPositions
        
        // Limit the trace length.
        if positions.count > Self.maxIndexCount {
            positions.removeFirst(2)
            uvs.removeFirst(2)
        }
    }

    static func generateIndices() -> [UInt32] {
        var indices: [UInt32] = []
        for index in 0 ..< maxIndexCount {
            indices.append(contentsOf: [index, index + 1, index + 2])
            indices.append(contentsOf: [index + 2, index + 1, index])
        }
        return indices
    }
}

extension TraceMesh {
    var meshContents: MeshResource.Contents {
        var meshPart = MeshResource.Part(id: "TracePart", materialIndex: 0)
        // Set up the part and contents using the positions and precalculated indices.
        meshPart.positions = .init(positions)
        meshPart.textureCoordinates = .init(uvs)
        meshPart.triangleIndices = .init(Self.triangleIndices.prefix((positions.count - 2) * 6))

        var contents = MeshResource.Contents()
        contents.models = [.init(id: "Trace", parts: [meshPart])]
        return contents
    }
}

extension ModelEntity {
    static func makeTraceModel(with contents: MeshResource.Contents) throws -> ModelEntity {
        guard let traceResource = try? TextureResource.load(named: "TrailGradient") else {
            fatalError("Unable to load trace texture.")
        }
        let traceMap = MaterialParameters.Texture(traceResource)
        var material = UnlitMaterial(color: .white)
        material.opacityThreshold = 0
        material.blending = .transparent(opacity: .init(texture: traceMap))
       
        return ModelEntity(mesh: try .generate(from: contents),
                           materials: [material])
    }
}
