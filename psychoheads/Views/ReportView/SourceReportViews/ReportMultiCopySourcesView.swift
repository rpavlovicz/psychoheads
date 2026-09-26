//
//  ReportMultiCopySourcesView.swift
//  psychoheads
//
//  Created by Codex on 4/28/26.
//

import SwiftUI

struct ReportMultiCopySourcesView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
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
        VStack(alignment: .leading) {
            Toggle("Sort Descending", isOn: $isSortedDescending)
                .tint(.blue)
                .padding(.bottom, 4)
            
            if multiCopySources.isEmpty {
                Text("No sources with more than one copy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                List(multiCopySources, id: \.id) { source in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.title)
                            Text(source.dateString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(source.ncopies) copies")
                            .foregroundColor(.blue)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct ReportMultiCopySourcesView_Previews: PreviewProvider {
    static var previews: some View {
        ReportMultiCopySourcesView()
            .environmentObject(SourceModel())
    }
}
