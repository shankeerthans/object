//
//  ImmersiveView.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import SwiftUI
import RealityKit

@MainActor
struct ImmersiveView: View {
    @Environment(RecognitionModel.self) private var recognitionModel
    
    var body: some View {
        RealityView { content in
            content.add(recognitionModel.getRootEntity())
            
            if recognitionModel.dataProvidersSupported {
                recognitionModel.runARSession()
            }
        }
        .onDisappear() {
            #if  targetEnvironment(simulator)
            print(".....")
            #else
            recognitionModel.stopARSession()
            #endif
        }

    }
    
}

#Preview {
    ImmersiveView()
}
