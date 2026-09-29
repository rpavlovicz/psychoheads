//
//  ReportTopSourcesView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//

import SwiftUI

struct ReportTopSourcesView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var isSortedDescending = true
    
    var sortedSourceCounts: [(name: String, count: Int)] {
        let sourceCounts = sourceModel.sourceCounts
        return isSortedDescending ? sourceCounts : sourceCounts.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Toggle(isOn: $isSortedDescending) {}
                    .labelsHidden()
                    .tint(.blue)
                    .scaleEffect(0.8)
                    .frame(width: 50)
                Image(systemName: isSortedDescending ? "arrow.down.to.line.compact" : "arrow.up.to.line.compact")
                    .font(.body)
                    .foregroundStyle(isSortedDescending ? Color.accentColor : Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sort order")
            .accessibilityValue(isSortedDescending ? "Descending" : "Ascending")
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sortedSourceCounts.enumerated()), id: \.element.name) { index, source in
                        Button {
                            navigationStateManager.selectionPath.append(.libraryForTitle(source.name))
                        } label: {
                            HStack {
                                Text(source.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(source.count)")
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if index < sortedSourceCounts.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
    }
}

struct ReportTopSourcesView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                ReportTopSourcesView()
            }
        }
        .environmentObject(SourceModel())
        .environmentObject(NavigationStateManager())
    }
}
