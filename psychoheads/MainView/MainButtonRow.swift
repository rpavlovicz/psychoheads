//
//  MainButtonRow.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/24/23.
//

import SwiftUI

struct MainButtonRow: View {

    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @State private var showingMoreOptions = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isLandscape: Bool = false
    
    // Determine if we should show all buttons in one row
    private var shouldShowAllButtons: Bool {
        return isLandscape && UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // All buttons in a single row
    var allButtons: some View {
        HStack(alignment: .lastTextBaseline) {
            Spacer()
            
            // Image Capture
            NavigationLink(value: SelectionState.imageCapture, label: {
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "camera")
                            .font(.system(size: 26, weight: .regular))
                            .padding(8)
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .frame(height: 40)
                    Text("Add to DB")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Library View
            NavigationLink(value: SelectionState.library, label: {
                VStack(spacing: 4) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Library")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Collage View
            NavigationLink(value: SelectionState.collageView, label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Collage")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Search
            NavigationLink(value: SelectionState.searchClippings(nil), label: {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Search")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Report Views
            NavigationLink(value: SelectionState.reportView, label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack.badge.person.crop")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Reports")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Settings
            NavigationLink(value: SelectionState.accountSettings, label: {
                VStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Settings")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Diagnostics
            NavigationLink(value: SelectionState.imageDiagnostics, label: {
                VStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Diagnostics")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Temp Clipping (temporary debug button)
            Button(action: {
                navigationStateManager.selectionPath.append(.tempClippingView)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "eye.circle")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Temp Clip")
                        .font(.caption2)
                }
            }
            
            Spacer()
        }
    }
    
    // Primary buttons (shown by default on smaller screens)
    var primaryButtons: some View {
        HStack(alignment: .lastTextBaseline) {
            Spacer()
            
            // Add View
            NavigationLink(value: SelectionState.imageCapture, label: {
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "camera")
                            .font(.system(size: 26, weight: .regular))
                            .padding(8)
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .frame(height: 40)
                    Text("Add to DB")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Library View
            NavigationLink(value: SelectionState.library, label: {
                VStack(spacing: 4) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Library")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // View Three
            NavigationLink(value: SelectionState.collageView, label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Collage")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Search
            NavigationLink(value: SelectionState.searchClippings(nil), label: {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Search")
                        .font(.caption2)
                }
            
            })
                        
            Spacer()
        }
    }
    
    // Secondary buttons (shown when More is pressed on smaller screens)
    var secondaryButtons: some View {
        HStack(alignment: .lastTextBaseline) {
            Spacer()
            
            // Report Views
            NavigationLink(value: SelectionState.reportView, label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack.badge.person.crop")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Reports")
                        .font(.caption2)
                }
            })
            
            Spacer()
                        
            // Settings
            NavigationLink(value: SelectionState.accountSettings, label: {
                VStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Settings")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Diagnostics
            NavigationLink(value: SelectionState.imageDiagnostics, label: {
                VStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Diagnostics")
                        .font(.caption2)
                }
            })
            
            Spacer()
            
            // Temp Clipping (temporary debug button)
            Button(action: {
                navigationStateManager.selectionPath.append(.tempClippingView)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "eye.circle")
                        .font(.system(size: 26, weight: .regular))
                        .frame(height: 40)
                    Text("Temp Clip")
                        .font(.caption2)
                }
            }
            
            Spacer()
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()

            if shouldShowAllButtons {
                // Show all buttons in one row for iPad landscape
                allButtons
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            } else {
                // Show primary/secondary buttons with More button for smaller screens
                HStack(spacing: 0) {
                    // Dynamic content area
                    if showingMoreOptions {
                        secondaryButtons
                    } else {
                        primaryButtons
                    }
                
                    // Fixed More button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingMoreOptions.toggle()
                        }
                    }) {
                        Image(systemName: showingMoreOptions ? "chevron.right" : "ellipsis")
                            .font(.system(size: 26, weight: .regular))
                            .padding(10)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            // Check orientation on appear
            isLandscape = UIDevice.current.orientation.isLandscape
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Update orientation when device rotates
            isLandscape = UIDevice.current.orientation.isLandscape
        }
    }
}

struct MainButtonRow_Previews: PreviewProvider {
    static var previews: some View {
        MainButtonRow()
            .environmentObject(SourceModel())
            .environmentObject(NavigationStateManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
