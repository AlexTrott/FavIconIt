//
//  ContentView.swift
//  faviconit
//
//  Created by Alex Trott on 08/03/2026.
//

import SwiftUI

enum AppState {
    case dropZone
    case preview(FaviconResult)
}

struct ContentView: View {
    @State private var appState: AppState = .dropZone

    var body: some View {
        Group {
            switch appState {
            case .dropZone:
                DropZoneView { result in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        appState = .preview(result)
                    }
                }
            case .preview(let result):
                PreviewView(result: result) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        appState = .dropZone
                    }
                }
            }
        }
        .frame(minWidth: 480, idealWidth: 560, minHeight: 400, idealHeight: 650)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
