//
//  ClippingView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/26/25.
//


//
//  ClippingView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/18/23.
//

import SwiftUI
import CoreData

struct ClippingView: View {
    
    @ObservedObject var clipping: Clipping
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager

    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var showAlert = false
    @State private var clippingToDelete: Clipping?
    
    @State private var expanded: Bool = false
    
    var source: Source? {
        sourceModel.sources.first { $0.id == clipping.sourceId }
    }
    
    var body: some View {
        VStack {
            
            AsyncImage2(clipping: clipping, placeholder: clipping.imageThumb ?? UIImage(), imageUrlMid: clipping.imageUrlMid, frameHeight: 450)
                .padding(.vertical)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack(alignment: .top) {
                        Text("Source: ").bold()
                        if let source = source {
                            NavigationLink(value: SelectionState.sourceView(source), label: {
                                SourceFormView(source: source)
                            })
//                            VStack(alignment: .leading) {
//                                Text(source.title)
//                                    .fontWeight(.semibold)
//                                if let issue = source.issue, !issue.isEmpty {
//                                    Text(source.issue!)
//                                        .font(.subheadline)
//                                }
//                                Text(source.dateString)
//                                    .font(.subheadline)
//                            }
                        }
                    }
                    
                    if clipping.isHead && !clipping.isBody {
                        var clippingNameSource = sourceModel.createSourceFromClippingName(clippingName: clipping.name)
                        HStack {
                            Text("Name: ").bold()
                            NavigationLink(value: SelectionState.sourceView(clippingNameSource), label: {
                                Text("\(clipping.name)")
                                }
                            )
                        }
                    }

                    Text("Date Added: ").bold() + Text("\(formatDate(date: clipping.added))")
                    Text("Tags: ").bold() + Text("\(clipping.tags.joined(separator: ", "))")
                    DisclosureGroup("additional information", isExpanded: $expanded) {
                        
                        HStack {
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("height = \(String(format: "%.2f", clipping.height)) cm")
                                    .font(.subheadline)
                                if clipping.headHeight == nil {
                                    Text("head height = N/A")
                                        .font(.subheadline)
                                } else {
                                    Text("head height = \(String(format: "%.2f", clipping.headHeight!)) cm")
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("width = \(String(format: "%.2f", clipping.width)) cm")
                                    .font(.subheadline)
                                if clipping.headWidth == nil {
                                    Text("head width = N/A")
                                        .font(.subheadline)
                                } else {
                                    Text("head width = \(String(format: "%.2f", clipping.headWidth!)) cm")
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            if (clipping.isHead && !clipping.isBody) {
                                Text("lookingDirection: \(clipping.lookingDirection ?? "")")
                                    .font(.subheadline)

                            }
                            Text("id: \(clipping.id)")
                                .font(.subheadline)
                            Text("source id: \(clipping.sourceId)")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("isHead = \(String(clipping.isHead))")
                                Text("isBody = \(String(clipping.isBody))")
                                Text("isAnimal = \(String(clipping.isAnimal))")
                                Text("isMan = \(String(clipping.isMan))")
                                Text("isWoman = \(String(clipping.isWoman))")
                                Text("isTrans = \(String(clipping.isTrans))")
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("isWhite = \(String(clipping.isWhite))")
                                Text("isBlack = \(String(clipping.isBlack))")
                                Text("isLatino = \(String(clipping.isLatino))")
                                Text("isAsian = \(String(clipping.isAsian))")
                                Text("isNative = \(String(clipping.isNative))")
                                Text("isIndian = \(String(clipping.isIndian))")
                                Text("isB&W = \(String(clipping.isBlackAndWhite))")
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        
//                        VStack(alignment: .leading, spacing: 5) {
//                            Text("image ULR = \(clipping.imageUrl)")
//                            Text("image ULR (mid) = \(clipping.imageUrlMid)")
//                            Text("image ULR (thumb) = \(clipping.imageUrlThumb)")
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        NavigationLink(value: SelectionState.editClippingView(clipping), label: {
                            Label("Edit Clipping", systemImage: "pencil")
                        })
                            
                        Button(role: .destructive) {
                            clippingToDelete = clipping
                            showAlert = true
                        } label: {
                            Label("Delete Clipping", systemImage: "trash")
                        }
                        .padding(.vertical,10)
                        
                    } // DisclosureGroup
                } // text VStack
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
            }
                
            
        } // main view VStack
        .padding(.horizontal, 10)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Delete Clipping"),
                  message: Text("Are you sure you want to delete this clipping from the database?"),
                  primaryButton: .destructive(Text("Delete")) {
                guard let clipping = clippingToDelete else { return }
                DeviceAuth.authenticate(reason: "Authenticate to delete this clipping") { success in
                    guard success else { return }
                    sourceModel.deleteClipping(clipping)
                    updateClippingTags(clipping: clipping)
                    updateHeadNameData(clipping: clipping)
                    navigationStateManager.popBack()
                }
            },
                  secondaryButton: .cancel()
            )
        }
        
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
    }
    
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
        
    }

    
}

class MockClipping: Clipping {

    override init() {
        super.init()
        self.id = "470690C2-AD75-4A6F-80EB-8B14EADDE9ED"
        self.sourceId = "FFD2B806-5E6C-4CB3-B8DC-A8E9C863F79A"
        self.isHead = true
        self.isBody = true
        self.isAnimal = false
        self.isMan = false
        self.isWoman = true
        self.isTrans = false
        self.isWhite = true
        self.isBlack = false
        self.isLatino = false
        self.isAsian = false
        self.isIndian = false
        self.isNative = false
        self.isBlackAndWhite = false
        self.name = "Anna Nicole Smith"
        self.tags = ["Anna Nicole Smith", "Anna Nicole", "Anna", "Playboy", "Marilyn Monroe", "seven year itch"]
        self.imageThumb = UIImage(named: "clippingThumb_1")
        self.height = 6.60
        self.headHeight = nil
        self.width = 5.40
        self.headWidth = nil
        
        self.imageUrl = "clippingImages/470690C2-AD75-4A6F-80EB-8B14EADDE9ED.png"
        self.imageUrlMid = "clippingImages/470690C2-AD75-4A6F-80EB-8B14EADDE9ED_mid.png"
        self.imageUrlThumb = "clippingImages/470690C2-AD75-4A6F-80EB-8B14EADDE9ED_thumb.png"

        self.added = Date()
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MockHeadClipping: Clipping {

    override init() {
        super.init()
        self.id = "CBA7ADE4-6533-49A6-A131-9FF02C484A2F"
        self.sourceId = "68386F17-C04F-4372-ADF1-9AE9EB6FF13D"
        self.isHead = true
        self.isBody = false
        self.isAnimal = false
        self.isMan = false
        self.isWoman = true
        self.isTrans = false
        self.isWhite = true
        self.isBlack = false
        self.isLatino = false
        self.isAsian = false
        self.isIndian = false
        self.isNative = false
        self.isBlackAndWhite = false
        self.name = "Anna Nicole Smith"
        self.tags = ["Anna Nicole Smith", "Anna Nicole", "Anna", "Playboy", "blonde"]
        self.imageThumb = UIImage(named: "clippingThumb_2")
        self.height = 7.15
        self.headHeight = 5.20
        self.width = 4.20
        self.headWidth = 4.20
        
        self.imageUrl = "clippingImages/CBA7ADE4-6533-49A6-A131-9FF02C484A2F.png"
        self.imageUrlMid = "clippingImages/CBA7ADE4-6533-49A6-A131-9FF02C484A2F_mid.png"
        self.imageUrlThumb = "clippingImages/CBA7ADE4-6533-49A6-A131-9FF02C484A2F_thumb.png"

        self.added = Date()
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

struct ClippingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClippingView(clipping: MockClipping())
                .environmentObject(SourceModel())
                .environmentObject(NavigationStateManager())
                .previewDisplayName("Body Clipping")
            ClippingView(clipping: MockHeadClipping())
                .environmentObject(SourceModel())
                .environmentObject(NavigationStateManager())
                .previewDisplayName("Head Clipping")
        }
    }
}
