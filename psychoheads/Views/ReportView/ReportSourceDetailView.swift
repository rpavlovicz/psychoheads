//
//  ReportSourceDetailView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  SourceDetailReportView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/9/24.
//

import SwiftUI
import Charts

struct ReportSourceDetailView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    
    @State private var minYear: Int?
    @State private var maxYear: Int?
    @State private var isScrollable: Bool = false // State property for toggle
    
    var body: some View {
        
        List {
            
            Section {
                
                ReportSourceSimpleView()
                
            }
            
            Section(header: Text("number of sources per year")) {
                
                ReportSourceChartView()
                
            }
            
            Section {
                ReportTopSourcesView()
            }
            
            Section(header: Text("sources with more than one copy")) {
                ReportMultiCopySourcesView()
            }
            
            Section(header: Text("average number of clippings per source")) {
                
                ReportAverageClippingsChartView()
                
            }
            
            Section(header: Text("average number of clippings per source 2")) {
                
                ReportAverageClippingsChartView2()
                
            }
            
            Section(header: Text("number of sources added per year")) {
                
                ReportSourcesPerYearView()
                
            }
            
            
            
        } // list
        
    } // body
}

//struct ReportSourceDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReportSourceDetailView()
//            .environmentObject(SourceModel())
//            .environmentObject(NavigationStateManager())
//    }
//}
