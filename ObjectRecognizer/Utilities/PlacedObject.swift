//
//  PlacedObject.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import RealityKit
import SwiftUI

class PlacedObject: Entity {
    
    private let renderContent: ModelEntity
    static let collisionGroup = CollisionGroup(rawValue: 1 << 29)
    
    var color: Color = .black
    
    @MainActor
    init(renderContentToClone: ModelEntity) async {
        renderContent = renderContentToClone.clone(recursive: true)
        super.init()
        name = renderContent.name
        scale = renderContent.scale
        renderContent.scale = .one
        
        guard let model = renderContent.model else { return }
        
        do {
            let shape = try await ShapeResource.generateConvex(from: model.mesh)
            let physicsMaterial = PhysicsMaterialResource.generate(restitution: 0.0)
            let physicsBodyComponent = PhysicsBodyComponent(shapes: [shape], mass: 1.0, material: physicsMaterial, mode: .static)
            components.set(physicsBodyComponent)
            components.set(CollisionComponent(shapes: [shape], filter: CollisionFilter(group: PlacedObject.collisionGroup, mask: .all)))
            components.set(InputTargetComponent(allowedInputTypes: [.direct, .indirect]))
            components.set(GroundingShadowComponent(castsShadow: true))
            addChild(renderContent)
            print("\(name) created")
        } catch {
            print("Error while generating shape")
        }
    }
                           
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
}
