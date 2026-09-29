//
//  ReportMultiCopySourcesView.swift
//  psychoheads
//
//  Created by Codex on 4/28/26.
//

import SwiftUI

struct ReportMultiCopySourcesView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var isSortedDescending = true
    
    private var multiCopySources: [Source] {
        sourceModel.sources.filter { $0.ncopies > 1 }
            .sorted { lhs, rhs in
                if isSortedDescending {
                    if lhs.ncopies != rhs.ncopies { return lhs.ncopies > rhs.ncopies }
                } else {
                    if lhs.ncopies != rhs.ncopies { return lhs.ncopies < rhs.ncopies }
                }
                return lhs.title < rhs.title
            }
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
            
            if multiCopySources.isEmpty {
                Text("No sources with more than one copy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(multiCopySources.enumerated()), id: \.element.id) { index, source in
                            Button {
                                navigationStateManager.selectionPath.append(.sourceView(source))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.title)
                                            .foregroundColor(.primary)
                                        Text(source.dateString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(source.ncopies) copies")
                                        .foregroundColor(.blue)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if index < multiCopySources.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
        }
    }
}

struct ReportMultiCopySourcesView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                ReportMultiCopySourcesView()
            }
        }
        .environmentObject(SourceModel())
        .environmentObject(NavigationStateManager())
    }
}
