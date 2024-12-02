//
//  RecognitionModel.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import UIKit
import SwiftUI
import ARKit
import RealityKit

extension UIColor {
    var name: String {
        switch self {
        case .systemGreen:
            "System Green"
        case .red:
            "Red"
        case .green:
            "Green"
        case .blue:
            "Blue"
        case .yellow:
            "Yellow"
        default:
            "Other"
        }
    }
}

@Observable
class RecognitionModel {
    private let numOfObjects: Int = 5
    private var persistenceManager: PersistenceManager
    
    private let rootEntity: Entity
    private let deviceLocation: Entity
    private let raycastOrigin: Entity
    private let highlightEntity: Entity
    private let worldTracking = WorldTrackingProvider()
    private let arSession = ARKitSession()
    
    private let placementState = PlacementState()
    var highlightStatus: HighlightStatus = .none
    
    @MainActor
    init() {
        rootEntity = Entity()
        deviceLocation = Entity()
        raycastOrigin = Entity()
        highlightEntity = Entity()
        deviceLocation.addChild(raycastOrigin)
        
        let raycastDownwardAngle = 15.0 * (Float.pi / 180)
        raycastOrigin.orientation = simd_quatf(angle: -raycastDownwardAngle, axis: [1.0, 0.0, 0.0])
        
        persistenceManager = PersistenceManager(worldTracking: worldTracking, rootEntity: rootEntity)
        setupHighlightEntity()
        createObjects()
    }
    
    var dataProvidersSupported: Bool {
        WorldTrackingProvider.isSupported
    }
    
    func getRootEntity() -> Entity {
        return rootEntity
    }
    
    @MainActor
    func setupHighlightEntity() {
        let model = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [UnlitMaterial(color: .magenta)])
        model.transform.translation += [0, 0.4, 0.2]
        highlightEntity.addChild(model)
        highlightEntity.name = "HighlighEntity"
    }
    
    @MainActor
    private func createObjects() {
        let colors: [UIColor] = [.systemGreen, .red, .green, .blue, .yellow]
        let locations: [SIMD3<Float>] = [[-1, 0, -1],
                                         [-0.5, 0, -2],
                                         [0, 0, -1],
                                         [0.5, 0, -2],
                                         [1, 0, -1]]
        
        for i in 0..<numOfObjects {
            let content = ModelEntity(mesh: .generateCylinder(height: 0.8, radius: 0.2), materials: [UnlitMaterial(color: colors[i])])
            content.transform.translation = [0,0.4,0]
            content.name = " Cylinder \(colors[i].name)"
            Task {
                let object = await PlacedObject(renderContentToClone: content)
                object.position = locations[i]
                object.color = Color(colors[i])
                rootEntity.addChild(object)
                persistenceManager.track(object: object)
            }
        }
    }
    
    @MainActor
    func runARSession() {
        Task {
            do {
                try await arSession.run([worldTracking])
                await processDeviceAnchorUpdates()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func stopARSession() {
        arSession.stop()
    }
    
    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(function: queryAndProcessLatestDeviceAnchor, withFrequency: 90)
    }
    
    @MainActor
    private func queryAndProcessLatestDeviceAnchor() async {
        guard worldTracking.state == .running else { return }
        
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        placementState.deviceAnchorPresent = deviceAnchor != nil
        
        guard let deviceAnchor, deviceAnchor.isTracked else { return }
        deviceLocation.transform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        await checkWhichObjectDeviceIsPointingAt(deviceAnchor)
    }
    
   @MainActor
    private func checkWhichObjectDeviceIsPointingAt(_ deviceAnchor: DeviceAnchor) async {
        let origin: SIMD3<Float> = raycastOrigin.transformMatrix(relativeTo: nil).translation
        let direction: SIMD3<Float> = -raycastOrigin.transformMatrix(relativeTo: nil).zAxis
        let collisionMask = PlacedObject.collisionGroup
        
        if let result = rootEntity.scene?.raycast(origin: origin, direction: direction, query: .nearest, mask: collisionMask).first {
            print("Highlighted Object \(result.entity.name)")
            if let pointedAtObject = persistenceManager.object(for: result.entity) {
                setHighlightedObject(pointedAtObject)
                highlightStatus = .highlighted(pointedAtObject.name, pointedAtObject.color)
                pointedAtObject.addChild(highlightEntity)
            } else {
                highlightStatus = .none
                highlightEntity.removeFromParent()
            }
        } else {
            highlightStatus = .none
            highlightEntity.removeFromParent()
        }
    }
    
    private func setHighlightedObject(_ objectToHighlight: PlacedObject?) {
        guard placementState.highlightedObject != objectToHighlight else {
            return
        }
        placementState.highlightedObject = objectToHighlight
        guard let objectToHighlight else { return }
        
        
    }
}

extension RecognitionModel {
    @MainActor
    func run(function: () async -> Void, withFrequency hz: UInt64) async {
        while true {
            if Task.isCancelled {
                return
            }
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }
            await function()
        }
    }
}
