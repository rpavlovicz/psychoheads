//
//  SearchClippingView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  SearchClippingView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/21/23.
//

import SwiftUI
import CoreData

struct SearchClippingView: View {
    
    enum Field: Hashable {
        case tagSearchField
    }
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    
    @State var searchText: String = ""
    @State private var isTagSearchActive: Bool = false
    @State private var expandSheet: Bool = false
    
    // Add state for swipe sheet presentation
    @State private var showSwipeSheet: Bool = false
    @State private var swipeStartIndex: Int = 0
    
    @State private var searchHeads: Bool = true
    @State private var searchTags: Bool = false
    @State private var searchAllHeads: Bool = false
    @State private var searchAllBodies: Bool = false
    @State private var lookingDirection: LookingDirection?
    
    // Filter state variables
    @State private var filterMan: Bool = false
    @State private var filterWoman: Bool = false
    @State private var filterTrans: Bool = false
    @State private var filterWhite: Bool = false
    @State private var filterBlack: Bool = false
    @State private var filterLatino: Bool = false
    @State private var filterAsian: Bool = false
    @State private var filterIndian: Bool = false
    @State private var filterNative: Bool = false
    @State private var filterBlackAndWhite: Bool = false
    @State private var filterAnimal: Bool = false
    
    // Height range state variables
    @State private var minHeight: Double = 3.0
    @State private var maxHeight: Double = 15.0
    @State private var heightRange: ClosedRange<Double> = 3.0...15.0
    
    // Dynamic range calculation
    var dynamicHeightRange: ClosedRange<Double> {
        let allClippings = sourceModel.clippings
        let heights = allClippings.map { $0.height }.filter { $0 > 0 }
        
        guard !heights.isEmpty else { return 3.0...15.0 }
        
        let minAvailable = heights.min() ?? 3.0
        let maxAvailable = heights.max() ?? 15.0
        
        return minAvailable...maxAvailable
    }
    
    let placeholderImage: UIImage? = UIImage(named: "clipping_thumb")
    
    @FocusState private var focusedField: Field?
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: ClippingTag.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \ClippingTag.count, ascending: false)]) var clippingTags: FetchedResults<ClippingTag>
    
    @FetchRequest(entity: HeadName.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \HeadName.count, ascending: false)]) var headNames: FetchedResults<HeadName>
    
    var existingTags: [String] {
        clippingTags.map { $0.tagString ?? "" }
    }
    
    var existingHeadNames: [String] {
        headNames.map { $0.name ?? "" }
    }
    
    var clippings: [Clipping]? = nil
    
//    var filteredClippings: [Clipping] {
//        if let clippings = clippings {
//            return clippings
//        } else {
//            return sourceModel.sources.flatMap { $0.clippings }
//                .filter { clipping in
//                    let nameMatch = searchHeads && clipping.name.lowercased().contains(searchText.lowercased())
//                    let tagMatch = searchTags && clipping.tags.contains { tag in
//                        tag.lowercased().contains(searchText.lowercased())
//                    }
//                    let directionMatch = (clipping.isHead && !clipping.isBody) && (lookingDirection == nil || clipping.lookingDirection == lookingDirection?.rawValue)
//                    return (nameMatch || tagMatch) && (!clipping.isHead || directionMatch)
//                }
//        }
//    }
    
    var filteredClippings: [Clipping] {
        if let clippings = clippings {
            // Apply directionMatch filter specifically to the provided clippings
            return clippings.filter { clipping in
                let directionMatch = (clipping.isHead && !clipping.isBody) && (lookingDirection == nil || clipping.lookingDirection == lookingDirection?.rawValue)
                return !clipping.isHead || directionMatch
            }
        } else {
            let allClippings = sourceModel.clippings
            
            // First, filter by All Heads or All Bodies if selected
            var filteredClippings = allClippings
            if searchAllHeads {
                // All Heads: only clippings that are heads but NOT bodies
                filteredClippings = filteredClippings.filter { $0.isHead && !$0.isBody }
            } else if searchAllBodies {
                // All Bodies: clippings that are bodies (can also be heads)
                filteredClippings = filteredClippings.filter { $0.isBody }
            }
            
            // Apply gender filters
            let activeGenderFilters = [filterMan, filterWoman, filterTrans].filter { $0 }
            if !activeGenderFilters.isEmpty {
                filteredClippings = filteredClippings.filter { clipping in
                    if filterMan && clipping.isMan { return true }
                    if filterWoman && clipping.isWoman { return true }
                    if filterTrans && clipping.isTrans { return true }
                    return false
                }
            }
            
            // Apply race filters
            let activeRaceFilters = [filterWhite, filterBlack, filterLatino, filterAsian, filterIndian, filterNative].filter { $0 }
            if !activeRaceFilters.isEmpty {
                filteredClippings = filteredClippings.filter { clipping in
                    if filterWhite && clipping.isWhite { return true }
                    if filterBlack && clipping.isBlack { return true }
                    if filterLatino && clipping.isLatino { return true }
                    if filterAsian && clipping.isAsian { return true }
                    if filterIndian && clipping.isIndian { return true }
                    if filterNative && clipping.isNative { return true }
                    return false
                }
            }
            
            // Apply black and white filter (separate from race filters)
            if filterBlackAndWhite {
                filteredClippings = filteredClippings.filter { $0.isBlackAndWhite }
            }
            
            // Apply animal filter
            if filterAnimal {
                filteredClippings = filteredClippings.filter { $0.isAnimal }
            }
            
            // Apply height filter
            let hasHeightFilter = minHeight > dynamicHeightRange.lowerBound || maxHeight < dynamicHeightRange.upperBound
            if hasHeightFilter {
                filteredClippings = filteredClippings.filter { clipping in
                    clipping.height >= minHeight && clipping.height <= maxHeight
                }
            }
            
            // Then apply search text filters
            return filteredClippings.filter { clipping in
                let nameMatch = searchHeads && clipping.name.lowercased().contains(searchText.lowercased())
                let tagMatch = searchTags && clipping.tags.contains { tag in
                    tag.lowercased().contains(searchText.lowercased())
                }
                
                // If animal or black & white filters are active, show all matching clippings
                let hasDisplayFilter = filterAnimal || filterBlackAndWhite
                if hasDisplayFilter {
                    let hasTextFilter = !searchText.isEmpty && (searchHeads || searchTags)
                    if hasTextFilter {
                        return nameMatch || tagMatch
                    } else {
                        return true // Show all clippings matching the display filter when no text filter
                    }
                }
                
                // If All Heads is selected, show all head clippings (with optional text filtering)
                if searchAllHeads {
                    let hasTextFilter = !searchText.isEmpty && (searchHeads || searchTags)
                    if hasTextFilter {
                        return nameMatch || tagMatch
                    } else {
                        return true // Show all head clippings when no text filter
                    }
                } else if searchAllBodies {
                    // If All Bodies is selected, show all body clippings (with optional text filtering)
                    let hasTextFilter = !searchText.isEmpty && (searchHeads || searchTags)
                    if hasTextFilter {
                        return nameMatch || tagMatch
                    } else {
                        return true // Show all body clippings when no text filter
                    }
                } else {
                    // Normal search behavior
                    return nameMatch || tagMatch
                }
            }.filter { clipping in
                // Apply direction filter to head clippings only (but not to body clippings)
                if clipping.isHead && !clipping.isBody {
                    // Only apply direction filter to pure head clippings
                    let directionMatch = lookingDirection == nil || clipping.lookingDirection == lookingDirection?.rawValue
                    return directionMatch
                } else {
                    // For body clippings or mixed head/body clippings, don't apply direction filter
                    return true
                }
            }
        }
    }
    
    var body: some View {
        
        VStack {
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(Array(filteredClippings.enumerated()), id: \.element.id) { index, clipping in
                        
                        // Replace NavigationLink with Button to trigger sheet
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
            .padding(.horizontal)// ScrollView
            
            Spacer()
            
            // MARK: - expandable sheet
            Button {
                expandSheet.toggle()
            } label: {
                Image(systemName: "chevron.compact.up")
            }
            .padding(.bottom, 5)
                            .sheet(isPresented: $expandSheet) {
                
                Form {
                    Section(header: Text("Search Type")) {
                        SearchSelectorView1(
                            searchHeads: $searchHeads, 
                            searchTags: $searchTags, 
                            searchAllHeads: $searchAllHeads, 
                            searchAllBodies: $searchAllBodies,
                            lookingDirection: $lookingDirection,
                            filterMan: $filterMan,
                            filterWoman: $filterWoman,
                            filterTrans: $filterTrans,
                            filterWhite: $filterWhite,
                            filterBlack: $filterBlack,
                            filterLatino: $filterLatino,
                            filterAsian: $filterAsian,
                            filterIndian: $filterIndian,
                            filterNative: $filterNative,
                            filterBlackAndWhite: $filterBlackAndWhite,
                            filterAnimal: $filterAnimal,
                            minHeight: $minHeight,
                            maxHeight: $maxHeight,
                            heightRange: .constant(dynamicHeightRange)
                        )
                    }
                }
                .background(Color.clear) // Set the background to clear
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.large] : [.medium, .large])
            }
            .background(Color.clear) // Set the background to clear

            
            // MARK: - filter search results
            let sortedHeadNames = existingHeadNames.filter({ sourceText in searchText == "" ? true : sourceText.lowercased().contains(searchText.lowercased())})
            
            if (isTagSearchActive && !sortedHeadNames.isEmpty) {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(sortedHeadNames, id: \.self) { headName in
                            TagView2(tag: headName) {
                                searchText = headName
                                focusedField = nil
                            }
                        }
                    }
                    .padding(.leading, 20)
                    .frame(height: 30)
                }
            }
            
            // MARK: - search bar
            TextField("Search", text: $searchText)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding()
                .padding(.top, -10)
                .overlay(
                    Group {
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .padding(.vertical)
                            .padding(.trailing)
                            .padding(.top, -10)
                        }
                    },
                    alignment: .trailing
                )
                .focused($focusedField, equals: .tagSearchField)
                .onChange(of: focusedField) { newValue in
                    isTagSearchActive = (newValue == .tagSearchField)
                }
                .onChange(of: dynamicHeightRange) { newRange in
                    // Reset slider to full range when available range changes
                    minHeight = newRange.lowerBound
                    maxHeight = newRange.upperBound
                }
            
        } // main VStack
        // Sheet presentation for ClippingsSwipeView
        .sheet(isPresented: $showSwipeSheet) {
            NavigationStack {
                ClippingsSwipeView(clippings: filteredClippings, currentIndex: $swipeStartIndex)
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
        }
        
        
    }
}

struct SearchClippingView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSourceModel = SourceModel()
        
        // Create mock clippings for preview
        let mockClipping1 = Clipping()
        mockClipping1.id = "1"
        mockClipping1.name = "John Doe"
        mockClipping1.tags = ["actor", "hollywood", "leading_man"]
        mockClipping1.isHead = true
        mockClipping1.isBody = false
        mockClipping1.lookingDirection = "left"
        mockClipping1.imageUrlMid = "mock_url_1"
        
        let mockClipping2 = Clipping()
        mockClipping2.id = "2"
        mockClipping2.name = "Jane Smith"
        mockClipping2.tags = ["actress", "drama", "award_winner"]
        mockClipping2.isHead = true
        mockClipping2.isBody = false
        mockClipping2.lookingDirection = "right"
        mockClipping2.imageUrlMid = "mock_url_2"
        
        let mockClipping3 = Clipping()
        mockClipping3.id = "3"
        mockClipping3.name = "Bob Wilson"
        mockClipping3.tags = ["character_actor", "comedy"]
        mockClipping3.isHead = true
        mockClipping3.isBody = false
        mockClipping3.lookingDirection = "fullFace"
        mockClipping3.imageUrlMid = "mock_url_3"
        
        let mockSource = Source(title: "Mock Magazine", year: "2024", month: "July")
        mockSource.clippings = [mockClipping1, mockClipping2, mockClipping3]
        mockSourceModel.sources = [mockSource]
        
        return Group {
            // Default state
            SearchClippingView()
                .environmentObject(mockSourceModel)
                .environmentObject(NavigationStateManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .previewDisplayName("SearchClippingView - Default")
            
            // With search text
            SearchClippingView()
                .environmentObject(mockSourceModel)
                .environmentObject(NavigationStateManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .onAppear {
                    // Simulate search text
                    // Note: This would need to be implemented with a way to set initial state
                }
                .previewDisplayName("SearchClippingView - With Results")
        }
    }
}

