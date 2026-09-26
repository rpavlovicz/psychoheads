//
//  ProgressReportSimpleView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  SourceReportView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 7/6/24.
//

import SwiftUI
import Charts

struct ProgressReportSimpleView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(verbatim: "Sources added in \(sourceModel.currentYear): \(sourceModel.sourcesAddedCurrentYear)")
                .padding(.bottom, 5)
            Text(verbatim: "Sources clipped in \(sourceModel.currentYear): \(sourceModel.sourcesClippedCurrentYear)")
                .padding(.bottom, 5)
            
            Text(verbatim:"Clippings added in \(sourceModel.currentYear): \(sourceModel.clippingsAddedCurrentYear)")
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensures left alignment
        
    } // body
}

//struct ProgressReportSimpleView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProgressReportSimpleView()
//            .environmentObject(SourceModel())
//            .environmentObject(NavigationStateManager())
//    }
//}
