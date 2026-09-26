//
//  ReportTopMaleHeadsView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  ReportTopSourcesView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 7/13/24.
//


import SwiftUI
import Charts

struct ReportTopMaleHeadsView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var isSortedDescending = true
    
    var sortedMaleHeadCounts: [(name: String, count: Int)] {
        let maleHeadCounts = sourceModel.maleHeadsNames
        return isSortedDescending ? maleHeadCounts : maleHeadCounts.reversed()
    }
    
    var uniqueMaleNamesCount: Int {
        sortedMaleHeadCounts.filter { $0.name.lowercased() != "unknown" }.count
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Total unique male names: \(uniqueMaleNamesCount)")
                //.font(.headline)
                .padding(.bottom, 10)
            
            Toggle("Sort Descending", isOn: $isSortedDescending)
                .tint(.blue)
                .padding(.bottom)
            
            List(sortedMaleHeadCounts, id: \.name) { head in
                HStack {
                    Text(head.name)
                    Spacer()
                    Text("\(head.count)")
                }
            }
            .listStyle(PlainListStyle())
        } // VStack
        
    } // body
}

struct ReportTopMaleHeadsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportTopMaleHeadsView()
            .environmentObject(SourceModel())
            .environmentObject(NavigationStateManager())
    }
}
