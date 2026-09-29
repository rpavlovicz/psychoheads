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
    
    // Grid vs scattered presentation
    @State private var isScatterMode: Bool = false
    @State private var scatterPositions: [CGPoint] = []
    @State private var scatterDisplaySizes: [CGSize] = []
    @State private var scatterGeometrySize: CGSize = .zero
    
    private let scatterMargin: CGFloat = 16
    private let cmToPoints: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52.85 : 60.8
    
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
    
    /// Head clippings only (isHead and not isBody), sorted by size. Used for scatter mode.
    var headSortedClippings: [Clipping] {
        let heads = source.clippings.filter { $0.isHead && !$0.isBody }
        return heads.sorted { $0.size > $1.size }
    }
    
    /// Clippings to display: all in grid mode, heads only in scatter mode.
    var displayedClippings: [Clipping] {
        isScatterMode ? headSortedClippings : allSortedClippings
    }
    
    /// Display size for one clipping in scatter mode: respects aspect ratio, relative scale to others,
    /// and caps so the largest fits in 1/4 of the view. Never upscales.
    private func scatterDisplaySize(for clipping: Clipping, viewSize: CGSize) -> CGSize {
        let naturalW = CGFloat(clipping.width) * cmToPoints
        let naturalH = CGFloat(clipping.height) * cmToPoints
        let list = headSortedClippings
        guard let largest = list.first else { return CGSize(width: naturalW, height: naturalH) }
        let largestW = CGFloat(largest.width) * cmToPoints
        let largestH = CGFloat(largest.height) * cmToPoints
        let largestNaturalArea = largestW * largestH
        let viewArea = viewSize.width * viewSize.height
        let maxArea = viewArea / 4
        let scale: CGFloat
        if largestNaturalArea <= maxArea {
            scale = 1.0
        } else {
            scale = sqrt(maxArea / largestNaturalArea)
        }
        let finalScale = min(scale, 1.0)
        return CGSize(width: naturalW * finalScale, height: naturalH * finalScale)
    }
    
    /// Generate display sizes and random positions for scatter mode; largest stays within 1/4 of view.
    private func updateScatterPositions(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let list = headSortedClippings
        scatterDisplaySizes = list.map { scatterDisplaySize(for: $0, viewSize: size) }
        scatterPositions = list.indices.map { i in
            let sz = scatterDisplaySizes[i]
            let halfW = sz.width / 2
            let halfH = sz.height / 2
            let minX = halfW + scatterMargin
            let maxX = size.width - halfW - scatterMargin
            let minY = halfH + scatterMargin
            let maxY = size.height - halfH - scatterMargin
            let cx: CGFloat
            let cy: CGFloat
            if maxX >= minX, maxY >= minY {
                cx = CGFloat.random(in: minX...maxX)
                cy = CGFloat.random(in: minY...maxY)
            } else {
                cx = size.width / 2
                cy = size.height / 2
            }
            return CGPoint(x: cx, y: cy)
        }
    }
    
    var body: some View {
        VStack {
            if isScatterMode {
                // Scattered layout: proportional sizes (largest ≤ 1/4 view), aspect ratio preserved, no upscale
                GeometryReader { geometry in
                    ZStack {
                        ForEach(displayedClippings.indices, id: \.self) { index in
                            let clipping = displayedClippings[index]
                            let displaySize = scatterDisplaySizes.indices.contains(index)
                                ? scatterDisplaySizes[index]
                                : scatterDisplaySize(for: clipping, viewSize: geometry.size)
                            Button(action: {
                                swipeStartIndex = index
                                showSwipeSheet = true
                            }) {
                                AsyncImage2(
                                    clipping: clipping,
                                    placeholder: placeholderImage ?? UIImage(),
                                    imageUrlMid: clipping.imageUrlMid,
                                    frameHeight: displaySize.height
                                )
                                .frame(width: displaySize.width, height: displaySize.height)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .position(scatterPositions.indices.contains(index) ? scatterPositions[index] : CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        scatterGeometrySize = geometry.size
                        updateScatterPositions(size: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        scatterGeometrySize = newSize
                        updateScatterPositions(size: newSize)
                    }
                    .onChange(of: isScatterMode) { _, newValue in
                        if newValue {
                            updateScatterPositions(size: scatterGeometrySize)
                        }
                    }
                }
                .clipped()
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
                                AsyncImage1(clipping: clipping, placeholder: placeholderImage ?? UIImage())
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
                ClippingsSwipeView(clippings: displayedClippings, currentIndex: $swipeStartIndex, sheetPath: $sheetPath)
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
