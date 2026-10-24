//
//  LibrarySourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/26/25.
//


//
//  LibrarySourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/12/23.
//

import SwiftUI
import Combine
import FirebaseStorage

struct LibrarySourceView: View {
    
    @ObservedObject var source: Source
    let placeholderImage: UIImage? = UIImage(named: "clipping_thumb")
    
    // Add state for sheet presentation
    @State private var showSwipeSheet: Bool = false
    @State private var swipeStartIndex: Int = 0
    @State private var sheetPath: [SelectionState] = []
    
    // Grid vs head-row presentation
    @State private var isScatterMode: Bool = false
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    /// All clippings, sorted (heads first, then by size). Used for grid mode.
    var allSortedClippings: [Clipping] {
        source.clippings.sorted { clipping1, clipping2 in
            switch (clipping1.isHead, clipping1.isBody, clipping2.isHead, clipping2.isBody) {
            case (true, _, false, _): return true
            case (false, _, true, _): return false
            case (true, false, true, true): return true
            case (true, true, true, false): return false
            default: return clipping1.size > clipping2.size
            }
        }
    }
    
    /// Heads with a real size, largest first. Used for the row layout and its swipe sheet.
    var headSortedClippings: [Clipping] {
        source.clippings
            .filter { $0.isHead && !$0.isBody && $0.width > 0 && $0.height > 0 }
            .sorted { $0.size > $1.size }
    }
    
    /// Clippings to display: all in grid mode, sized heads only in row mode.
    var displayedClippings: [Clipping] {
        isScatterMode ? headSortedClippings : allSortedClippings
    }
    
    var body: some View {
        VStack {
            if isScatterMode {
                SearchHeadCollageView(
                    clippings: displayedClippings,
                    placeholder: placeholderImage ?? UIImage(),
                    onSelect: { clipping in
                        if let index = displayedClippings.firstIndex(where: { $0.id == clipping.id }) {
                            swipeStartIndex = index
                            showSwipeSheet = true
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Default grid layout
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(displayedClippings.indices, id: \.self) { index in
                            let clipping = displayedClippings[index]
                            Button(action: {
                                swipeStartIndex = index
                                showSwipeSheet = true
                            }) {
                                SourceGridThumbnail(clipping: clipping, placeholder: placeholderImage ?? UIImage())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            Text("total number of clippings = \(displayedClippings.count)")
                .font(.subheadline)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(source.title)
                        .font(.headline)
                    Text(source.dateString)
                        .font(.subheadline)
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button {
                        navigationStateManager.selectionPath.append(.edit(source))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                } preview: {
                    SourcePreviewCard(source: source)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isScatterMode.toggle() }) {
                    Image(systemName: isScatterMode ? "person.3" : "square.grid.2x2")
                        .imageScale(.large)
                        //.contentTransition(.opacity)
                        .animation(.easeOut(duration: 0.15), value: isScatterMode)
                }
            }
        }
        // Sheet presentation for ClippingsSwipeView
        .sheet(isPresented: $showSwipeSheet) {
            NavigationStack(path: $sheetPath) {
                ClippingsSwipeView(clippings: displayedClippings, currentIndex: $swipeStartIndex, sheetPath: $sheetPath, dismissToSourceID: source.id)
                    .environmentObject(sourceModel)
                    .environmentObject(navigationStateManager)
                    .environment(\.managedObjectContext, managedObjectContext)
                    .navigationDestination(for: SelectionState.self) { state in
                        switch state {
                        case .sourceView(let source):
                            LibrarySourceView(source: source)
                                .environmentObject(sourceModel)
                                .environmentObject(navigationStateManager)
                                .environment(\.managedObjectContext, managedObjectContext)
                        case .editClippingView(let clipping):
                            EditClippingView(clipping: clipping)
                                .environmentObject(sourceModel)
                                .environmentObject(navigationStateManager)
                                .environment(\.managedObjectContext, managedObjectContext)
                        case .editClippingSourceView(let clipping):
                            EditClippingSourceView(clipping: clipping)
                                .environmentObject(sourceModel)
                                .environmentObject(navigationStateManager)
                        case .searchForTag(let tag):
                            SearchClippingView(exactTag: tag)
                                .environmentObject(sourceModel)
                                .environmentObject(navigationStateManager)
                                .environment(\.managedObjectContext, managedObjectContext)
                        default:
                            EmptyView()
                        }
                    }
            }
            .presentationSizing(.page)
            .onDisappear { sheetPath = [] }
        }
    } // View
}

/// Grid cell for one clipping. Larger clippings still fit the slot. Smaller ones stay at life size.
private struct SourceGridThumbnail: View {
    let clipping: Clipping
    let placeholder: UIImage
    private let slotHeight: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            let size = displaySize(in: geo.size)
            AsyncImage1(clipping: clipping, placeholder: placeholder, displaySize: size)
                .frame(width: size.width, height: size.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: slotHeight)
    }

    /// Life size, or smaller when that would exceed the slot. Never larger than life size.
    private func displaySize(in slot: CGSize) -> CGSize {
        let lifeW = CGFloat(clipping.width) * SearchCollageLayout.cmToPoints
        let lifeH = CGFloat(clipping.height) * SearchCollageLayout.cmToPoints
        guard lifeW > 0, lifeH > 0, slot.width > 0, slot.height > 0 else {
            return slot
        }
        let scale = min(1, slot.width / lifeW, slot.height / lifeH)
        return CGSize(width: lifeW * scale, height: lifeH * scale)
    }
}


struct LibrarySourceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibrarySourceView(source: MockSource())
                .environmentObject(SourceModel())
                .environmentObject(NavigationStateManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

class MockSource: Source {

    override init() {
        super.init()
        self.title = "Playboy"
        self.year = "1994"
        self.month = "February"
        let clipping1 = Clipping()
        clipping1.id = "1"
        clipping1.imageThumb = UIImage(named: "clippingThumb_1")
        let clipping2 = Clipping()
        clipping2.id = "2"
        clipping2.imageThumb = UIImage(named: "clippingThumb_2")
        let clipping3 = Clipping()
        clipping3.id = "3"
        clipping3.imageThumb = UIImage(named: "clippingThumb_3")
        let clipping4 = Clipping()
        clipping4.id = "4"
        clipping4.imageThumb = UIImage(named: "clippingThumb_4")
        let clipping5 = Clipping()
        clipping5.id = "5"
        clipping5.imageThumb = UIImage(named: "clippingThumb_5")
        
        self.clippings = [clipping1, clipping2, clipping3, clipping4, clipping5]
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
