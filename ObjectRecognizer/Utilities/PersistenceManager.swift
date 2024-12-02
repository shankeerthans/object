//
//  PersistenceManager.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import ARKit
import RealityKit

class PersistenceManager {
    private var objectsBeingAnchored: [UUID: PlacedObject] = [:]
    private var movingObjects: [PlacedObject] = []
    private var placedObjects: [PlacedObject] = []
    
    private let worldTracking: WorldTrackingProvider
    private var rootEntity: Entity
    
    init(worldTracking: WorldTrackingProvider, rootEntity: Entity) {
        self.worldTracking = worldTracking
        self.rootEntity = rootEntity
    }
    
    func object(for entity: Entity) -> PlacedObject? {
        return placedObjects.first(where: {$0 === entity})
    }
    
    func track(object: PlacedObject) {
        placedObjects.append(object)
    }
    
    @MainActor
    func attachObjectToWorldAnchor(_ object: PlacedObject) async {
        let anchor = WorldAnchor(originFromAnchorTransform: object.transformMatrix(relativeTo: nil))
        movingObjects.removeAll(where: { $0 === object })
        objectsBeingAnchored[anchor.id] = object
        do {
            try await worldTracking.addAnchor(anchor)
        } catch {
            if let worldTrackingError = error as? WorldTrackingProvider.Error, worldTrackingError.code == .worldAnchorLimitReached {
                print(
                    """
                    Unable to place object "\(object.name)". You’ve placed the maximum number of objects.
                    Remove old objects before placing new ones.
                    """
                )
            } else {
                print("Failed to add world anchor \(anchor.id) with error: \(error).")
            }
            objectsBeingAnchored.removeValue(forKey: anchor.id)
            object.removeFromParent()
            return
        }
    }
}
