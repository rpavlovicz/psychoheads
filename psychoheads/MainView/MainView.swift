//
//  MainView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/10/23.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @StateObject var navigationStateManager = NavigationStateManager()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        
        NavigationStack(path: $navigationStateManager.selectionPath) {
    
            VStack {
        
                Spacer()
                
                Text("Welcome to Psychoheads")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                // Button Row
                MainButtonRow()
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .environmentObject(sourceModel)
                    .environmentObject(navigationStateManager)
 
            }
//            .onAppear() {
//                // ensure reload only happens after logout
//                if sourceModel.sources.isEmpty {
//                    sourceModel.reloadSources()
//                }
//            }
            .navigationDestination(for: SelectionState.self) { state in
                switch state {
                    case .imageCapture:
                        ImageCaptureView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)
                    case .accountSettings:
                        AccountSettingsView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)
                    case .newUser:
                        NewUserView()
                            .environmentObject(navigationStateManager)
                    case .existingUser:
                        ExistingUserView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .library:
                        LibraryView(sourceModel: sourceModel)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)
                    case .sourceView(let source):
                        LibrarySourceView(source: source)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)
                    case .clippingView(let clipping):
                        ClippingView(clipping: clipping)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .clippingsSwipeView(let clippings, let currentIndex):
                        ClippingsSwipeViewWrapper(clippings: clippings, initialIndex: currentIndex)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .searchClippings(let clippings):
                        SearchClippingView(clippings: clippings)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .editClippingView(let clipping):
                        EditClippingView(clipping: clipping)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .editClippingSourceView(let clipping):
                        EditClippingSourceView(clipping: clipping)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .collageView:
                        CollageView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .reportView:
                        ReportView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .reportSourceDetailView:
                        ReportSourceDetailView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .reportClippingDetailView:
                        ReportClippingDetailView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .progressReportView:
                        ProgressReportView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                    case .tempClippingView:
                        TempClippingView()
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)

                    case .edit(let source):
                        EditSourceView(source: source)
                            .environmentObject(sourceModel)
                            .environmentObject(navigationStateManager)
                            .environment(\.managedObjectContext, viewContext)
                }
            }
             
        } // NavigationStack
        
        
    }
}

struct ClippingsSwipeViewWrapper: View {
    let clippings: [Clipping]
    let initialIndex: Int
    @State private var currentIndex: Int
    
    init(clippings: [Clipping], initialIndex: Int) {
        self.clippings = clippings
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ClippingsSwipeView(clippings: clippings, currentIndex: $currentIndex)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(SourceModel())
            .environmentObject(NavigationStateManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
