//
//  ObjectRecognizerApp.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import SwiftUI

@MainActor
@main
struct ObjectRecognizerApp: App {
    @State var immersiveStyle: ImmersionStyle = .mixed
    @State var recognitionModel = RecognitionModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(recognitionModel)
        }
        
        ImmersiveSpace(id: Constants.immersiveIdentifier.objectPlacementAndRecognizer) {
            ImmersiveView()
                .environment(recognitionModel)
        }
        .immersionStyle(selection: $immersiveStyle, in: .mixed)
    }
}
