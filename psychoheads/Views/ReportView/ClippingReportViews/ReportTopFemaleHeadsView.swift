//
//  ReportTopFemaleHeadsView.swift
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

struct ReportTopFemaleHeadsView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var isSortedDescending = true
    
    var sortedFemaleHeadCounts: [(name: String, count: Int)] {
        let femaleHeadCounts = sourceModel.femaleHeadsNames
        return isSortedDescending ? femaleHeadCounts : femaleHeadCounts.reversed()
    }
    
    var uniqueFemaleNamesCount: Int {
        sortedFemaleHeadCounts.filter { $0.name.lowercased() != "unknown" }.count
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Total unique female names: \(uniqueFemaleNamesCount)")
                //.font(.headline)
                .padding(.bottom, 10)
            
            Toggle("Sort Descending", isOn: $isSortedDescending)
                .tint(.blue)
                .padding(.bottom)
            
            List(sortedFemaleHeadCounts, id: \.name) { head in
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

struct ReportTopFemaleHeadsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportTopFemaleHeadsView()
            .environmentObject(SourceModel())
            .environmentObject(NavigationStateManager())
    }
}
