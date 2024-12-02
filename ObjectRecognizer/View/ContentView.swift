//
//  ContentView.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import UIKit
import SwiftUI
import RealityKit

enum HighlightStatus {
    case none
    case highlighted(String, Color)
    
    var message: String {
        switch self {
        case .none:
            "Nothing Highlighted"
        case .highlighted(let name, _):
            "\(name) highlighted"
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            Color.orange
        case .highlighted(_, let color):
            color
        }
    }
}

@MainActor
struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(RecognitionModel.self) private var recognitionModel
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var immersiveSpaceOpened: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                Task {
                    if !immersiveSpaceOpened {
                        switch await openImmersiveSpace(id: Constants.immersiveIdentifier.objectPlacementAndRecognizer) {
                        case .opened:
                            immersiveSpaceOpened = true
                            print("Immersive Space has been opened")
                        case .userCancelled:
                            print("User cancelled the Immersive Space")
                        case .error:
                            print("Error on opening the Immersive Space")
                        @unknown default:
                            break
                        }
                    }
                }
            }, label: {
                Text("Open into Your Space")
            })
            
            Button(action: {
                Task {
                    if immersiveSpaceOpened {
                        await dismissImmersiveSpace()
                        immersiveSpaceOpened = false
                    }
                }
            }, label: {
                Text("Exit from Your Space")
            })
            
            HighlightMessage(status: recognitionModel.highlightStatus)
        }
        .padding()
        .onChange(of: scenePhase) {
            if (scenePhase == .background) {
                immersiveSpaceOpened = false
            }
        }
    }
}

struct HighlightMessage: View {
    let status: HighlightStatus
    var body: some View {
        Text(status.message)
            .foregroundStyle(status.color)
            .bold()
            .animation(.bouncy)
            .frame(height: 30)
            .padding(.all, 30)
    }
}

#Preview(windowStyle: .automatic) {
    HighlightMessage(status: .none)
}
