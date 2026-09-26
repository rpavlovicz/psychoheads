//
//  ClippingsSwipeView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/26/25.
//


//
//  ClippingsSwipeView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 1/7/24.
//


import SwiftUI
import CoreData

struct ClippingsSwipeView: View {
    
    var clippings: [Clipping]
    @Binding var currentIndex: Int
    /// When non-nil, Edit pushes onto this path (sheet). Otherwise uses main navigation path.
    var sheetPath: Binding<[SelectionState]>? = nil
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @Environment(\.dismiss) private var dismiss

    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var showAlert = false
    @State private var clippingToDelete: Clipping?
    
    @State private var expanded: Bool = false
    
    // Calculate proper image size based on clipping dimensions and available space
    private func calculateImageSize(for clipping: Clipping) -> CGSize {
        // Use a fraction of the screen width to ensure it fits in the sheet
        let maxWidthFraction: CGFloat = 0.65 // Use 70% of available width
        let maxHeightFraction: CGFloat = 0.6 // Use 60% of available height
        
        let screenWidth = UIScreen.main.bounds.width * maxWidthFraction
        let screenHeight = UIScreen.main.bounds.height * maxHeightFraction
        
        // Convert cm to points using device-specific scale factor
        let cmToPoints: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52.85 : 60.8
        let clippingWidthPoints = CGFloat(clipping.width) * cmToPoints
        let clippingHeightPoints = CGFloat(clipping.height) * cmToPoints
        
        // Calculate scale to fit within the fraction of available space while maintaining aspect ratio
        let widthScale = screenWidth / clippingWidthPoints
        let heightScale = screenHeight / clippingHeightPoints
        let scale = min(widthScale, heightScale, 1.0) // Don't scale up beyond actual size
        
        return CGSize(
            width: clippingWidthPoints * scale,
            height: clippingHeightPoints * scale
        )
    }
    
    // Calculate the scale indicator text
    private func scaleIndicatorText(for clipping: Clipping, imageSize: CGSize) -> String {
        // Convert cm to points using device-specific scale factor
        let cmToPoints: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 52.85 : 60.8
        let originalWidthPoints = CGFloat(clipping.width) * cmToPoints
        let originalHeightPoints = CGFloat(clipping.height) * cmToPoints
        
        // Calculate the scale factor
        let widthScale = imageSize.width / originalWidthPoints
        let heightScale = imageSize.height / originalHeightPoints
        let scale = min(widthScale, heightScale, 1.0) // Same logic as calculateImageSize
        
        // Format the scale as a percentage or "1x"
        if scale >= 0.99 {
            return "1x"
        } else {
            return String(format: "%.2fx", scale)
        }
    }
    
    var body: some View {
        Group {
            if clippings.indices.contains(currentIndex) {
                clippingContent(for: clippings[currentIndex])
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, 10)
        .onChange(of: clippings.count) { newCount in
            if newCount == 0 {
                dismiss()
            } else if currentIndex >= newCount {
                currentIndex = newCount - 1
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Delete Clipping"),
                  message: Text("Are you sure you want to delete this clipping from the database?"),
                  primaryButton: .destructive(Text("Delete")) {
                guard let clipping = clippingToDelete else { return }
                DeviceAuth.authenticate(reason: "Authenticate to delete this clipping") { success in
                    guard success else { return }
                    performDelete(clipping)
                }
            },
                  secondaryButton: .cancel()
            )
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    @ViewBuilder
    private func clippingContent(for clipping: Clipping) -> some View {
        let source = sourceModel.sources.first { $0.id == clipping.sourceId }
        let imageSize = calculateImageSize(for: clipping)
        
        VStack(spacing: 0) {
            // Image area fills all available space above the info box
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        HStack {
                            // Left chevron button
                            if currentIndex > 0 {
                                Button(action: {
                                    if currentIndex > 0 {
                                        currentIndex -= 1
                                    }
                                }) {
//                                    Image(systemName: "chevron.left")
//                                        .font(.title2)
//                                        .foregroundColor(.primary)
//                                        .padding(12)
//                                        .background(
//                                            Circle()
//                                                .fill(Color(.systemBackground))
//                                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
//                                        )
                                    Image(systemName: "chevron.compact.left")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                }
                                .transition(.opacity)
                                .disabled(currentIndex <= 0)
                            } else {
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()
                            // Image with swipe gesture
                            AsyncImage2(clipping: clipping, placeholder: clipping.imageThumb ?? UIImage(), imageUrlMid: clipping.imageUrlMid, frameHeight: imageSize.height)
                                .frame(width: min(imageSize.width, geometry.size.width - 40), height: imageSize.height)
                                .padding(.vertical)
                                .padding(.horizontal)
                                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                                    .onEnded { value in
                                        if value.translation.width < 0 && currentIndex < clippings.count - 1 {
                                            currentIndex += 1
                                        } else if value.translation.width > 0 && currentIndex > 0 {
                                            currentIndex -= 1
                                        }
                                    }
                                )
                            Spacer()
                            // Right chevron button
                            if currentIndex < clippings.count - 1 {
                                Button(action: {
                                    if currentIndex < clippings.count - 1 {
                                        currentIndex += 1
                                    }
                                }) {
                                    Image(systemName: "chevron.compact.right")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)

//                                    Image(systemName: "chevron.right")
//                                        .font(.title2)
//                                        .foregroundColor(.primary)
//                                        .padding(12)
//                                        .background(
//                                            Circle()
//                                                .fill(Color(.systemBackground))
//                                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
//                                        )
                                }
                                .transition(.opacity)
                                .disabled(currentIndex >= clippings.count - 1)
                            } else {
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal, 20)
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                // Size indicator overlay (always in the same place, bottom right of image area)
                HStack(spacing: 4) {
                    Image(systemName: "square.resize.down")
                        .font(.caption)
                    Text(scaleIndicatorText(for: clipping, imageSize: imageSize))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemBackground).opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                )
                .padding(.trailing, 2)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.linear(duration: 0.12), value: currentIndex)

            //Spacer()

            // Info box pinned to bottom
            ClippingInfoBoxView(
                clipping: clipping,
                source: source,
                expanded: $expanded,
                onEdit: {
                    if let sheetPath = sheetPath {
                        sheetPath.wrappedValue.append(.editClippingView(clipping))
                    } else {
                        navigationStateManager.selectionPath.append(.editClippingView(clipping))
                    }
                },
                onDelete: {
                    clippingToDelete = clipping
                    showAlert = true
                }
            )
        } // main view VStack
    }
    
    private func performDelete(_ clipping: Clipping) {
        let shouldDismiss = clippings.count <= 1
        if !shouldDismiss && currentIndex >= clippings.count - 1 && currentIndex > 0 {
            currentIndex -= 1
        }
        
        if shouldDismiss {
            dismiss()
        }
        
        sourceModel.deleteClipping(clipping)
        updateClippingTags(clipping: clipping)
        updateHeadNameData(clipping: clipping)
    }

    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func updateClippingTags(clipping: Clipping) {
        for tag in clipping.tags {
            let fetchRequest: NSFetchRequest<ClippingTag> = ClippingTag.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "tagString == %@", tag)
            
            do {
                let matchingTags = try managedObjectContext.fetch(fetchRequest)
                for matchingTag in matchingTags {
                    if matchingTag.count > 1 {
                        print("decrementing \(matchingTag.tagString!) ClippingTag count by 1")
                        matchingTag.count -= 1
                    } else {
                        print("deleting \(matchingTag.tagString!) ClippingTag from Core Data")
                        managedObjectContext.delete(matchingTag)
                    }
                }
                try managedObjectContext.save()
            } catch {
                print("Failed to fetch or save clipping tag in Core Data: \(error)")
            }
        }
    } // end updateClippingTags
    
    func updateHeadNameData(clipping: Clipping) {
        
        let fetchRequest: NSFetchRequest<HeadName> = HeadName.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", clipping.name)
        
        do {
            let matchingNames = try managedObjectContext.fetch(fetchRequest)
            for matchingName in matchingNames {
                if matchingName.count > 1 {
                    print("decrementing \(matchingName.name!) HeadName count by 1")
                    matchingName.count -= 1
                } else {
                    print("deleting \(matchingName.name!) HeadName from Core Data")
                    managedObjectContext.delete(matchingName)
                }
            }
            try managedObjectContext.save()
        } catch {
            print("Failed to fetch or save head name in Core Data: \(error)")
        }
    } // end updateHeadNameData
    
}

private struct ClippingInfoBoxView: View {
    let clipping: Clipping
    let source: Source?
    @Binding var expanded: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var sourceModel: SourceModel
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text("Source: ").bold()
                    if let source = source {
                        NavigationLink(value: SelectionState.sourceView(source), label: {
                            SourceFormView(source: source)
                        })
                    }
                }
                if clipping.isHead && !clipping.isBody {
                    let clippingNameSource = sourceModel.createSourceFromClippingName(clippingName: clipping.name)
                    HStack {
                        Text("Name: ").bold()
                        NavigationLink(value: SelectionState.sourceView(clippingNameSource), label: {
                            Text(clipping.name)
                        })
                    }
                }
                Text("Date Added: ").bold() + Text(formatDate(date: clipping.added))
                (Text("Tags: ").bold() + Text(clipping.tags.joined(separator: ", ")))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                DisclosureGroup("additional information", isExpanded: $expanded) {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("height = ") + Text(String(format: "%.2f", clipping.height)) + Text(" cm")
                                .font(.subheadline)
                            if clipping.headHeight == nil {
                                Text("head height = N/A")
                                    .font(.subheadline)
                            } else {
                                Text("head height = ") + Text(String(format: "%.2f", clipping.headHeight!)) + Text(" cm")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("width = ") + Text(String(format: "%.2f", clipping.width)) + Text(" cm")
                                .font(.subheadline)
                            if clipping.headWidth == nil {
                                Text("head width = N/A")
                                    .font(.subheadline)
                            } else {
                                Text("head width = ") + Text(String(format: "%.2f", clipping.headWidth!)) + Text(" cm")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    VStack(alignment: .leading, spacing: 5) {
                        if (clipping.isHead && !clipping.isBody) {
                            Text("lookingDirection: ") + Text(clipping.lookingDirection ?? "")
                                .font(.subheadline)
                        }
                        Text("id: ") + Text(clipping.id)
                            .font(.subheadline)
                        Text("source id: ") + Text(clipping.sourceId)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("isHead = ") + Text(String(clipping.isHead))
                            Text("isBody = ") + Text(String(clipping.isBody))
                            Text("isAnimal = ") + Text(String(clipping.isAnimal))
                            Text("isMan = ") + Text(String(clipping.isMan))
                            Text("isWoman = ") + Text(String(clipping.isWoman))
                            Text("isTrans = ") + Text(String(clipping.isTrans))
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("isWhite = ") + Text(String(clipping.isWhite))
                            Text("isBlack = ") + Text(String(clipping.isBlack))
                            Text("isLatino = ") + Text(String(clipping.isLatino))
                            Text("isAsian = ") + Text(String(clipping.isAsian))
                            Text("isNative = ") + Text(String(clipping.isNative))
                            Text("isIndian = ") + Text(String(clipping.isIndian))
                            Text("isB&W = ") + Text(String(clipping.isBlackAndWhite))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    Button(action: onEdit) {
                        Label("Edit Clipping", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Clipping", systemImage: "trash")
                    }
                    .padding(.vertical, 10)
                }
                .padding(.bottom, 4)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(Color(.systemGray5))
            .frame(maxWidth: .infinity, alignment: .center)
            .clipped()
        }
        .frame(maxHeight: 170)
    }
}


struct ClippingsSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ClippingsSwipeView(clippings: createMockClippings(), currentIndex: .constant(1))
                .environmentObject(createMockSourceModel())
                .environmentObject(NavigationStateManager())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
    
    static func createMockClippings() -> [Clipping] {
        let clipping1 = Clipping()
        clipping1.id = "1"
        clipping1.name = "John Doe"
        clipping1.imageThumb = UIImage(named: "clippingThumb_1")
        clipping1.imageUrlMid = "mock_url_1"
        clipping1.added = Date()
        clipping1.tags = ["actor", "hollywood"]
        clipping1.isHead = true
        clipping1.isBody = false
        clipping1.isMan = true
        clipping1.isWhite = true
        clipping1.height = 15.5
        clipping1.width = 12.0
        clipping1.headHeight = 8.0
        clipping1.headWidth = 6.0
        clipping1.lookingDirection = "left"
        clipping1.sourceId = "source1"
        
        let clipping2 = Clipping()
        clipping2.id = "2"
        clipping2.name = "Jane Smith"
        clipping2.imageThumb = UIImage(named: "clippingThumb_2")
        clipping2.imageUrlMid = "mock_url_2"
        clipping2.added = Date().addingTimeInterval(-86400) // Yesterday
        clipping2.tags = ["actress", "drama"]
        clipping2.isHead = true
        clipping2.isBody = false
        clipping2.isWoman = true
        clipping2.isWhite = true
        clipping2.height = 14.0
        clipping2.width = 11.5
        clipping2.headHeight = 7.5
        clipping2.headWidth = 5.8
        clipping2.lookingDirection = "right"
        clipping2.sourceId = "source2"
        
        let clipping3 = Clipping()
        clipping3.id = "3"
        clipping3.name = "Body Shot"
        clipping3.imageThumb = UIImage(named: "clippingThumb_3")
        clipping3.imageUrlMid = "mock_url_3"
        clipping3.added = Date().addingTimeInterval(-172800) // 2 days ago
        clipping3.tags = ["full_body", "fashion"]
        clipping3.isHead = false
        clipping3.isBody = true
        clipping3.isWoman = true
        clipping3.isWhite = true
        clipping3.height = 25.0
        clipping3.width = 18.0
        clipping3.sourceId = "source3"
        
        return [clipping1, clipping2, clipping3]
    }
    
    static func createMockSourceModel() -> SourceModel {
        let sourceModel = SourceModel()
        
        let source1 = Source(title: "Vogue Magazine", year: "2024", month: "January")
        source1.id = "source1"
        source1.imageThumb = UIImage(named: "source_thumb")
        
        let source2 = Source(title: "GQ Magazine", year: "2023", month: "December")
        source2.id = "source2"
        source2.imageThumb = UIImage(named: "source_thumb")
        
        let source3 = Source(title: "Vanity Fair", year: "2024", month: "February")
        source3.id = "source3"
        source3.imageThumb = UIImage(named: "source_thumb")
        
        sourceModel.sources = [source1, source2, source3]
        
        return sourceModel
    }
}




