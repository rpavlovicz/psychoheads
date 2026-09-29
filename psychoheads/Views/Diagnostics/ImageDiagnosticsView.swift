//
//  ImageDiagnosticsView.swift
//  psychoheads
//

import SwiftUI

struct ImageDiagnosticsView: View {
    
    enum Scope: String, CaseIterable, Identifiable {
        case clippings
        case sources
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .clippings: return "Clippings"
            case .sources: return "Sources"
            }
        }
    }
    
    @State private var scope: Scope = .clippings
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Scope", selection: $scope) {
                ForEach(Scope.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            switch scope {
            case .clippings:
                ClippingImageDiagnosticsView()
            case .sources:
                SourceImageDiagnosticsView()
            }
        }
        .navigationTitle("Image Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
