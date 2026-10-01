//
//  LibraryView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/25/25.
//

import SwiftUI
import FirebaseFirestore

enum LibraryLayoutMode: String {
    case list
    case magazine
}

struct LibraryView: View {
    enum Field: Hashable {
        case sourceSearchField
    }
    
    // why pass this explicitly as an ObservedObject instead if implicitly as an
    //  @EnvironmentObject var sourceModel: SourceModel
    @ObservedObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager

    @AppStorage("isThumbnailMode") private var isThumbnailMode: Bool = false
    @AppStorage("libraryLayoutMode") private var libraryLayoutModeRaw: String = LibraryLayoutMode.list.rawValue
    
    @State private var showAlert = false
    @State private var sourceToDelete: Source?
    @State private var sourceToEdit: Source?
    @State private var editActive = false
    
    @State var searchText: String = ""
    @State private var isTagSearchActive: Bool = false
    @State private var isSuggestionListDragging: Bool = false
    @FocusState private var focusedField: Field?
    @State private var sourceSortMode: LibrarySourceSortMode = .publicationDate
    /// `false` = Date newest-first / Title A→Z; `true` = Date oldest-first / Title Z→A
    @State private var isSortReversed: Bool = false
    @State private var sourceCoverageFilter: SourceCoverageFilter = .withClippings
    /// When set, match this title exactly (case-insensitive) instead of contains-search.
    private let exactTitleFilter: String?
    /// When set, only show sources from this publication year.
    private let yearFilter: Int?
    /// Session-only layout override (e.g. report → title opens in magazine without changing AppStorage).
    @State private var sessionLayoutMode: LibraryLayoutMode?
    
    private var libraryLayoutMode: LibraryLayoutMode {
        get { LibraryLayoutMode(rawValue: libraryLayoutModeRaw) ?? .list }
        nonmutating set { libraryLayoutModeRaw = newValue.rawValue }
    }
    
    private var effectiveLayoutMode: LibraryLayoutMode {
        sessionLayoutMode ?? libraryLayoutMode
    }
    
    private var isTitleScoped: Bool {
        exactTitleFilter != nil
    }
    
    private var isYearScoped: Bool {
        yearFilter != nil
    }
    
    private var searchFieldPrompt: String {
        isTitleScoped ? "Search date or issue" : "Search"
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var magazineColumns: [GridItem] {
        let minimum: CGFloat = isIPad ? 140 : 110
        return [GridItem(.adaptive(minimum: minimum), spacing: 12)]
    }
    
    init(
        sourceModel: SourceModel,
        initialSearchText: String = "",
        initialCoverageFilter: SourceCoverageFilter = .withClippings,
        exactTitleFilter: String? = nil,
        yearFilter: Int? = nil,
        startInMagazineRack: Bool = false
    ) {
        self.sourceModel = sourceModel
        self.exactTitleFilter = exactTitleFilter
        self.yearFilter = yearFilter
        _searchText = State(initialValue: initialSearchText)
        _sourceCoverageFilter = State(initialValue: initialCoverageFilter)
        _sessionLayoutMode = State(initialValue: startInMagazineRack ? .magazine : nil)
    }
    
    private var yearScopedSources: [Source] {
        sourceModel.sources.filter { matchesYearFilter($0) }
    }
    
    private var titlePoolForSearch: [Source] {
        isYearScoped ? yearScopedSources : sourceModel.sources
    }
    
    var sourceTitleSuggestions: [String] {
        let uniqueTitles = Array(Set(titlePoolForSearch.map { $0.title }.filter { !$0.isEmpty }))
        let filtered = uniqueTitles.filter { title in
            searchText.isEmpty || title.lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted()
    }
    
    /// True when the current query exactly matches a known title (computed once per filter pass).
    private var queryMatchesKnownTitleExactly: Bool {
        guard exactTitleFilter == nil else { return false }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return false }
        return titlePoolForSearch.contains {
            $0.title.caseInsensitiveCompare(query) == .orderedSame
        }
    }
    
    private var titleFilteredSources: [Source] {
        let exactKnown = queryMatchesKnownTitleExactly
        return sourceModel.sources.filter { source in
            matchesYearFilter(source) && matchesTitleFilter(source, queryMatchesKnownTitleExactly: exactKnown)
        }
    }
    
    private var shouldDisableUnclippedModes: Bool {
        !titleFilteredSources.contains(where: { $0.clippings.isEmpty })
    }
    
    private func makeFilteredSources() -> [Source] {
        let exactKnown = queryMatchesKnownTitleExactly
        return sourceModel.sources(for: sourceCoverageFilter).filter { source in
            matchesYearFilter(source)
                && matchesTitleFilter(source, queryMatchesKnownTitleExactly: exactKnown)
                && matchesSecondarySearch(source)
        }
        .sorted { lhs, rhs in
            SourcePublicationSortKey.shouldPrecede(lhs, rhs, mode: sourceSortMode, isReversed: isSortReversed)
        }
    }
    
    private func matchesYearFilter(_ source: Source) -> Bool {
        guard let yearFilter else { return true }
        let year = Int(source.year.trimmingCharacters(in: .whitespacesAndNewlines))
        return year == yearFilter
    }
    
    private func matchesTitleFilter(_ source: Source, queryMatchesKnownTitleExactly: Bool) -> Bool {
        if let exactTitleFilter {
            return source.title.caseInsensitiveCompare(exactTitleFilter) == .orderedSame
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        
        // If the query exactly matches a known title (e.g. autocomplete "Vanity Fair"),
        // require an exact title match so "Vanity Fair Italia" is not included.
        if queryMatchesKnownTitleExactly {
            return source.title.caseInsensitiveCompare(query) == .orderedSame
        }
        
        return source.title.lowercased().contains(query.lowercased())
    }
    
    /// When title-scoped, search filters date string and issue within that title pool.
    private func matchesSecondarySearch(_ source: Source) -> Bool {
        guard isTitleScoped else { return true }
        guard !searchText.isEmpty else { return true }
        let query = searchText.lowercased()
        if source.dateString.lowercased().contains(query) {
            return true
        }
        if let issue = source.issue, issue.lowercased().contains(query) {
            return true
        }
        return false
    }
    
    private func toggleLayoutMode() {
        let next: LibraryLayoutMode = effectiveLayoutMode == .list ? .magazine : .list
        if sessionLayoutMode != nil {
            sessionLayoutMode = next
        } else {
            libraryLayoutMode = next
        }
    }
    
    private func listLayout(sources: [Source]) -> some View {
        List {
            ForEach(sources) { source in
                Button {
                    navigationStateManager.selectionPath.append(.sourceView(source))
                } label: {
                    SourceRowView2(source: source, displayMode: isThumbnailMode ? .thumbnail : .minimal)
                        .environmentObject(source)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    NavigationLink(value: SelectionState.edit(source), label: { Label("Edit", systemImage: "pencil")})
                        .tint(.blue)

                    Button(role: .destructive) {
                        sourceToDelete = source
                        showAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        navigationStateManager.selectionPath.append(.sourceView(source))
                    } label: {
                        Label("Open Source", systemImage: "arrow.right.circle")
                    }
                } preview: {
                    SourcePreviewCard(source: source)
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .refreshable {
            sourceModel.updateSources()
        }
        .listStyle(.plain)
    }
    
    private func magazineLayout(sources: [Source]) -> some View {
        ScrollView {
            LazyVGrid(columns: magazineColumns, spacing: 12) {
                ForEach(sources) { source in
                    // Button (not NavigationLink) avoids SwiftUI auto-pushing when only one cell is present.
                    Button {
                        navigationStateManager.selectionPath.append(.sourceView(source))
                    } label: {
                        SourceMagazineCell(source: source)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            navigationStateManager.selectionPath.append(.sourceView(source))
                        } label: {
                            Label("Open Source", systemImage: "arrow.right.circle")
                        }
                        Button {
                            navigationStateManager.selectionPath.append(.edit(source))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            sourceToDelete = source
                            showAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } preview: {
                        SourcePreviewCard(source: source)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .refreshable {
            sourceModel.updateSources()
        }
    }
    
    var body: some View {
        let sources = makeFilteredSources()
        VStack {
            TextField(searchFieldPrompt, text: $searchText)
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
                .focused($focusedField, equals: .sourceSearchField)
                .onChange(of: focusedField) { newValue in
                    isTagSearchActive = (newValue == .sourceSearchField)
                }
            
            if !isTitleScoped && isTagSearchActive && !sourceTitleSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(sourceTitleSuggestions, id: \.self) { title in
                            TagView2(tag: title) {
                                guard !isSuggestionListDragging else { return }
                                searchText = title
                                focusedField = nil
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 44)
                .padding(.top, -16)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { _ in
                            isSuggestionListDragging = true
                        }
                        .onEnded { _ in
                            isSuggestionListDragging = false
                        }
                )
            }
            
            if effectiveLayoutMode == .magazine {
                magazineLayout(sources: sources)
            } else {
                listLayout(sources: sources)
            }

            Spacer(minLength: 0)
            
            HStack {
                Text("Number of sources: \(sources.count)")
                Spacer()
                if effectiveLayoutMode == .list {
                    Toggle(isOn: $isThumbnailMode) {}
                        .tint(.blue)
                        .scaleEffect(0.8)
                        .frame(width: 50)
                    Image(systemName: isThumbnailMode ? "arrow.up.and.down" : "arrow.up.to.line")
                        .font(Font.system(size: 15))
                        .foregroundStyle(isThumbnailMode ? Color.accentColor : Color.secondary)
                        .padding(.leading, 1)
                }
            }.padding(.horizontal, 20)
            .padding(.vertical, 12)
            
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Delete Source"),
                  message: Text("Are you sure you want to delete this source from the database?"),
                  primaryButton: .destructive(Text("Delete")) {
                guard let source = sourceToDelete else { return }
                DeviceAuth.authenticate(reason: "Authenticate to delete this source") { success in
                    if success {
                        sourceModel.deleteSource(source)
                    }
                }
            },
                  secondaryButton: .cancel()
            )
        }
        .onChange(of: searchText) { _ in
            enforceCoverageFilterValidity()
        }
        .onReceive(sourceModel.$sources) { _ in
            enforceCoverageFilterValidity()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(SourceCoverageFilter.allCases) { filter in
                        Button {
                            sourceCoverageFilter = filter
                        } label: {
                            if sourceCoverageFilter == filter {
                                Label(filter.displayName, systemImage: "checkmark")
                            } else {
                                Text(filter.displayName)
                            }
                        }
                        .disabled(shouldDisableUnclippedModes && filter != .withClippings)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sourceCoverageFilter.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        toggleLayoutMode()
                    } label: {
                        Image(systemName: effectiveLayoutMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    .accessibilityLabel(
                        effectiveLayoutMode == .list
                        ? "Switch to magazine rack view"
                        : "Switch to list view"
                    )
                    
                    Button(action: {
                        sourceSortMode = sourceSortMode == .alphabetical ? .publicationDate : .alphabetical
                    }) {
                        Image(systemName: sourceSortMode == .alphabetical ? "textformat.abc" : "calendar")
                    }
                    .accessibilityLabel(
                        sourceSortMode == .alphabetical
                        ? "Sorting alphabetically. Tap to sort by publication date."
                        : "Sorting by publication date. Tap to sort alphabetically."
                    )
                    
                    Button(action: {
                        isSortReversed.toggle()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel(
                        isSortReversed
                        ? "Sort inverted. Tap to use default order."
                        : "Tap to invert sort order."
                    )
                }
            }
        }
    }
    
    private func enforceCoverageFilterValidity() {
        if shouldDisableUnclippedModes && sourceCoverageFilter != .withClippings {
            sourceCoverageFilter = .withClippings
        }
    }
    
}

struct SourcePreviewCard: View {
    @ObservedObject var source: Source
    @StateObject private var imageLoader = ImageLoader()
    @State private var previewImage: UIImage?
    private let placeholderImage: UIImage = UIImage(named: "source_thumb") ?? UIImage()
    
    private var preferredPreviewImagePath: String {
        if !source.imageUrlMid.isEmpty {
            return source.imageUrlMid
        }
        if !source.imageUrlThumb.isEmpty {
            return source.imageUrlThumb.replacingOccurrences(of: "_thumb", with: "_mid")
        }
        return ""
    }
    
    private var addedDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: source.added)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                if let image = previewImage ?? source.imageThumb {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(uiImage: placeholderImage)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(12)
            
            Text(source.title)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            VStack(alignment: .leading, spacing: 6) {
                if let issue = source.issue, !issue.isEmpty {
                    Text(issue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(source.dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Added: \(addedDateText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Number of copies: \(source.ncopies)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(source.clippings.count) clippings")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(18)
        .frame(maxWidth: 460)
        .background(Color(.systemBackground))
        .onAppear {
            guard !preferredPreviewImagePath.isEmpty else { return }
            imageLoader.load(imagePath: preferredPreviewImagePath, useCache: true) { success, downloadedImage in
                if success, let downloadedImage {
                    previewImage = downloadedImage
                }
            }
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView(sourceModel: {
                let model = SourceModel()
                let source1 = Source(title: "Sample Magazine", year: "2023", month: "January")
                source1.id = "1"
                
                let source2 = Source(title: "Another Source", year: "2022", month: "December")
                source2.id = "2"
                
                let source3 = Source(title: "Test Publication", year: "2024", month: "March")
                source3.id = "3"
                
                let source4 = Source(title: "Vintage Collection", year: "1995", month: "August")
                source4.id = "4"
                
                let source5 = Source(title: "Modern Times", year: "2023", month: "November")
                source5.id = "5"
                
                let source6 = Source(title: "Classic Edition", year: "2000", month: "April")
                source6.id = "6"
                
                model.sources = [source1, source2, source3, source4, source5, source6]
                return model
            }())
            .environmentObject(NavigationStateManager())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
