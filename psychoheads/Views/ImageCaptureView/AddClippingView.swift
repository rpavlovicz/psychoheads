//
//  AddClippingView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  AddSourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/25/23.
//

import SwiftUI
import FirebaseFirestore
//import FirebaseFirestoreSwift
import CoreData

//import Alamofire
//import SwiftyJSON

struct AddClippingView: View {
    
    enum ActiveAlert: Identifiable {
        case success, measureError, uploadError
        
        var id: Int {
            switch self {
            case .success:
                return 1
            case .measureError:
                return 2
            case .uploadError:
                return 3
            }
        }
    }
    
    enum Field: Hashable {
        case sourceField
        case nameField
        case tagField
        case totalHeightField
        case totalWidthField
        case headHeightField
        case headWidthField
    }
    
    @EnvironmentObject var sourceModel: SourceModel
    
    let image: UIImage?
    
    @AppStorage("isHead") private var isHead: Bool = false
    @AppStorage("isBody") private var isBody: Bool = false
    @AppStorage("isAnimal") private var isAnimal: Bool = false
    @AppStorage("isMan") private var isMan: Bool = false
    @AppStorage("isWoman") private var isWoman: Bool = false
    @AppStorage("isTrans") private var isTrans: Bool = false
    @AppStorage("isWhite") private var isWhite: Bool = false
    @AppStorage("isBlack") private var isBlack: Bool = false
    @AppStorage("isLatino") private var isLatino: Bool = false
    @AppStorage("isAsian") private var isAsian: Bool = false
    @AppStorage("isIndian") private var isIndian: Bool = false
    @AppStorage("isNative") private var isNative: Bool = false
    @AppStorage("isBW") private var isBW: Bool = false
    @State private var sourceSearch: String = ""
    @AppStorage("name") var name: String = ""
    @State private var source: Source?
    @AppStorage("total_width") var widthString: String = ""
    @AppStorage("total_height") var heightString: String = ""
    @AppStorage("head_width") private var headWidthString: String = ""
    @AppStorage("head_height") private var headHeightString: String = ""
    @AppStorage("source_id") private var lastSourceId: String = ""
    @AppStorage("looking_direction") private var lookingDirectionString: String = ""
    @State private var lookingDirection: LookingDirection? = nil
    @State private var singleTag: String = ""
    @State private var tags: [String] = UserDefaults.standard.stringArray(forKey: "tags") ?? []
    
    // for autocompletion of total height/width
    @State private var aspectRatio: CGFloat?
    @State private var isHeightFieldUpdated = false
    @State private var isWidthFieldUpdated = false
    // for passing to DimensionRatioView
    @State private var headHeightRatio: CGFloat?
    @State private var headWidthRatio: CGFloat?
    @State private var isAspectRatioLocked = true
    
    @State private var showSourcePopup: Bool = false
    
    @State private var isSubmitting = false
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: ClippingTag.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \ClippingTag.count, ascending: false)]) var clippingTags: FetchedResults<ClippingTag>
    
    @FetchRequest(entity: HeadName.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \HeadName.count, ascending: false)]) var headNames: FetchedResults<HeadName>
    
    
//    var existingSourceNames: [String] {
//        let sources = sourceNames.map { $0.nameString ?? "" }
//        print("Number of existing sources: \(sources.count)")
//        
//        for sourceName in sourceNames {
//            if let sourceNameString = sourceName.nameString {
//                print("   sourceName: \(sourceNameString), Count: \(sourceName.count)")
//            }
//        }
//        return sources
//    }
    
    var existingTags: [String] {
        clippingTags.map { $0.tagString ?? "" }
    }
    
    var existingHeadNames: [String] {
        //headNames.map { $0.name ?? "" }
        let heads = headNames.map { $0.name ?? "" }
        print("Number of existing head names: \(heads.count)")
        
        for headName in headNames {
            if let headNameString = headName.name {
                print("   headName: \(headNameString), Count: \(headName.count)")
            }
        }
        return heads
    }
    
    @State private var isSourceSearchActive: Bool = false
    @State private var isTagSearchActive: Bool = false
    @State private var isHeadFieldActive: Bool = false
    
    @State private var tagHeight: CGFloat = 0.0
    
    //@State private var showAlert: Bool = false
    @State private var activeAlert: ActiveAlert? = nil
    @State private var errorMessage: String = ""
    
    @FocusState private var focusedField: Field?
    @State private var toggledTag: String?
    
    let constants = Constants()
    private var isFormComplete: Bool {
        if isBody || (isHead && isBody)  {
            return !widthString.isEmpty && !heightString.isEmpty && !tags.isEmpty && (source != nil)
        }
        else if isHead {
            return !widthString.isEmpty && !heightString.isEmpty && !headWidthString.isEmpty && !headHeightString.isEmpty && !tags.isEmpty && (source != nil) && !lookingDirectionString.isEmpty
        }
        else {
            return false
        }
    }
    @State private var isPressed = false
    @State private var isAdded = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View{
        
        let lookingDirectionValue = LookingDirection(rawValue: lookingDirectionString)
        
        let db = Firestore.firestore()
        let sourcesCollection = db.collection("sources")
        
        VStack(spacing: 0) {
            
            Text("Add Clipping Info")
                .padding(.vertical)
            
            Form {
                
                Section(header: Text("general info")) {
                    TypeSelectorView1(isHead: $isHead, isBody: $isBody, isAnimal: $isAnimal)
                    
                    TypeSelectorView2(isMan: $isMan, isWoman: $isWoman, isTrans: $isTrans, isWhite: $isWhite, isBlack: $isBlack, isLatino: $isLatino, isAsian: $isAsian, isIndian: $isIndian, isNative: $isNative, isBW: $isBW)
                    
                    if source != nil {
                        Button {
                            source = nil
                            focusedField = .sourceField
                        } label: {
                            SourceFormView(source: source!)
                                .foregroundColor(.black)
                        }
                    } else {
                        TextField("Source", text: $sourceSearch)
                            .focused($focusedField, equals: .sourceField)
                            .onChange(of: focusedField) { newValue in
                                isSourceSearchActive = (newValue == .sourceField)
                            }
                            .overlay(
                                Group {
                                    if sourceSearch != "" {
                                        Button(action: {
                                            sourceSearch = ""
                                            focusedField = .tagField
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                //.padding(.trailing, 10)
                                        }
                                        .padding(.vertical)
                                        //.padding(.trailing)
                                        //.padding(.top, -10)
                                    }
                                },
                                alignment: .trailing
                            )
                    }
                    
                    // MARK: - source search
                    if isSourceSearchActive {
                        ScrollView {
                            LazyVStack {
                                let sortedSources = sourceModel.sources.filter({ sourceText in sourceSearch == "" ? true : sourceText.title.lowercased().contains(sourceSearch.lowercased())})
                                    .sorted { (a, b) in
                                        if a.id == lastSourceId { return true }
                                        if b.id == lastSourceId { return false }
                                        return a.added > b.added
                                    }
                                
                                ForEach(sortedSources, id: \.self) { sourceItem in
                                    
                                    ZStack {
                                        
                                        SourceFormView(source: sourceItem)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, 2)
//                                            .simultaneousGesture(
//                                                LongPressGesture(minimumDuration: 1.5)
//                                                //                                                            .updating($showSourcePopup) { currentState, gestureState, _ in gestureState = currentState
//                                                //                                                            }
//                                                    .onChanged { _ in
//                                                        showSourcePopup = true
//                                                    }
//                                                    .onEnded { _ in
//                                                        showSourcePopup = false
//                                                    }
//                                            )
                                            .highPriorityGesture(
                                                TapGesture().onEnded { _ in
                                                    print("tap")
                                                    sourceSearch = sourceItem.title
                                                    source = sourceItem
                                                    isSourceSearchActive = false
                                                    focusedField = nil
                                                }
                                            )
                                        
//                                        if showSourcePopup {
//                                            VStack {
//                                                //Image("broken_image_link")
//                                                Image(uiImage: image!)
//                                                    .resizable()
//                                                    .aspectRatio(contentMode: .fit)
//                                                    .frame(width: 100)
//                                                    .padding()
//                                            }
//                                        }
                                        
                                    } // ZStack
                                    
                                } // ForEach
                            }
                            
                        }.frame(maxHeight: 170)
                    }
                    
                    // MARK: - head name entry
                    if isHead && !isBody {
                        TextField("Name", text: $name)
                            .autocorrectionDisabled(true)
                            .overlay(
                                Group {
                                    if !name.isEmpty {
                                        Button(action: {
                                            name = ""
                                            tags = []
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                //.padding(.trailing, 10)
                                        }
                                        .padding(.vertical)
                                        //.padding(.trailing)
                                        //.padding(.top, -10)
                                    }
                                },
                                alignment: .trailing
                            )
                            .onSubmit {
                                name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !tags.contains(name) {
                                    tags.append(name)
                                }
                                
                                // Fetch and aggregate existing tags for given name
                                let autoPopulatedTags = sourceModel.aggregatedTagsForName(name)
                                for tag in autoPopulatedTags where !tags.contains(tag) {
                                    tags.append(tag)
                                }
                            }
                            .focused($focusedField, equals: .nameField)
                            .onChange(of: focusedField) { newValue in
                                isHeadFieldActive = (newValue == .nameField)
                            }
                        
                        let sortedHeadNames = existingHeadNames.filter({ sourceText in name == "" ? true : sourceText.lowercased().contains(name.lowercased())})
                        
                        if (isHeadFieldActive && !sortedHeadNames.isEmpty) {
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(sortedHeadNames, id: \.self) { headName in
                                        TagView2(tag: headName) {
                                            name = headName
                                            if !tags.contains(name) {
                                                tags.append(name)
                                            }
                                            
                                            // Fetch and aggregate existing tags for given name
                                            let autoPopulatedTags = sourceModel.aggregatedTagsForName(name)
                                            for tag in autoPopulatedTags where !tags.contains(tag) {
                                                tags.append(tag)
                                            }
                                            focusedField = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - tag entry
                    TextField("Tags", text: $singleTag)
                        .autocorrectionDisabled(true)
                        .onSubmit {
                            singleTag = singleTag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !singleTag.isEmpty {
                                if !tags.contains(singleTag) {
                                    tags.append(singleTag)
                                    UserDefaults.standard.set(tags, forKey: "tags")
                                }
                                singleTag = ""
                                focusedField = .tagField
                            }
                        }
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .tagField)
                        .onChange(of: focusedField) { newValue in
                            isTagSearchActive = (newValue == .tagField)
                        }
                    
                    let sortedTags = existingTags.filter({ sourceText in singleTag == "" ? true : sourceText.lowercased().contains(singleTag.lowercased())})
                    //                    .sorted { (a, b) in
                    //                        if a.id == lastSourceId { return true }
                    //                        if b.id == lastSourceId { return false }
                    //                        return a.added > b.added
                    //                    }
                    
                    if (isTagSearchActive && !sortedTags.isEmpty) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                ForEach(sortedTags, id: \.self) { tag in
                                    if !tags.contains(tag) {
                                        TagView2(tag: tag) {
                                            tags.append(tag)
                                            singleTag = ""
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    
                    if !tags.isEmpty {
                        
                        // TODO: line wrap added tags
                        //                    Text("Tags: \(tags.joined(separator: ", "))")
                        //                    VStack {
                        //                        //WrappingHStack(items: tags)
                        //                        //    .modifier(GetHeightModifier(height: $tagHeight))
                        //                        //print("tagHeight = \(tagHeight)")
                        //                    }//.frame(height: tagHeight)
                        ForEach(tags, id: \.self) { tag in
                            TagView(tag: tag, onDelete: {
                                if let index = tags.firstIndex(of: tag) {
                                    tags.remove(at: index)
                                    UserDefaults.standard.set(tags, forKey: "tags")
                                    toggledTag = nil
                                }
                            }, toggledTag: $toggledTag)
                        }
                    }
                }
                
                // MARK: - dimensions fields
                Section(header:
                            HStack {
                    Text("Dimensions")
                    Spacer()
                    
                    //                            Button(action: {
                    //                                self.endEditing() // This will dismiss the keyboard
                    //                                focusedField = nil
                    //                            }, label: {
                    //                                NavigationLink(destination: DimensionRatioView(image: image!, headHeightRatio: $headHeightRatio, headWidthRatio: $headWidthRatio)) {
                    //                                    Image(systemName: "aspectratio")
                    //                                }
                    //                            })
                    Image(systemName: "aspectratio")
                    
                    Button(action: {
                        isAspectRatioLocked.toggle() // This will toggle the state between true and false
                        aspectRatio = isAspectRatioLocked ? image!.size.height / image!.size.width : nil
                    }, label: {
                        Image(systemName: isAspectRatioLocked ? "lock" : "lock.slash")
                    })
                    
                    
                }
                        
                ) {
                    HStack {
                        Text("Total: ")
                            .frame(width: 60)
                        TextField(" height (cm)", text: $heightString)
                            .focused($focusedField, equals: .totalHeightField)
                            .onTapGesture {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedField = .totalHeightField
                                }
                                //focusedField = .totalHeightField
                            }
                            .frame(width: 100)
                            .onChange(of: heightString) { newValue in
                                guard focusedField == .totalHeightField else {
                                    return
                                }
                                if let newHeight = Float(newValue) {
                                    if let aspectRatio = aspectRatio {
                                        let newWidth = newHeight / Float(aspectRatio)
                                        widthString = String(format: "%.2f%", newWidth)
                                        if let widthRatio = headWidthRatio {
                                            let widthRatioFloat = Float(widthRatio)
                                            headWidthString = String(format: "%.2f", newWidth * widthRatioFloat)
                                        }
                                    }
                                    if let heightRatio = headHeightRatio {
                                        let heightRatioFloat = Float(heightRatio)
                                        headHeightString = String(format: "%.2f", newHeight * heightRatioFloat)
                                    }
                                }
                            }
                            .keyboardType(.decimalPad)
                        
                        Text("x")
                        TextField(" width (cm)", text: $widthString)
                            .focused($focusedField, equals: .totalWidthField)
                            .onChange(of: widthString) { newValue in
                                guard focusedField == .totalWidthField else {
                                    return
                                }
                                if let newWidth = Float(newValue) {
                                    if let aspectRatio = aspectRatio {
                                        let newHeight = newWidth * Float(aspectRatio)
                                        heightString = String(format: "%.2f%", newHeight)
                                        if let heightRatio = headHeightRatio {
                                            let heightRatioFloat = Float(heightRatio)
                                            headHeightString = String(format: "%.2f", newHeight * heightRatioFloat)
                                        }
                                    }
                                    if let widthRatio = headWidthRatio {
                                        let widthRatioFloat = Float(widthRatio)
                                        headWidthString = String(format: "%.2f", newWidth * widthRatioFloat)
                                    }
                                }
                            }
                            .keyboardType(.decimalPad)
                        
                    }
                    if (isHead && !isBody) {
                        HStack {
                            Text("Head: ")
                                .frame(width: 60)
                            TextField("height (cm)", text: $headHeightString)
                                .focused($focusedField, equals: .headHeightField)
                                .frame(width: 100)
                            
                                .onChange(of: headHeightString) { newValue in
                                    guard focusedField == .headHeightField else {
                                        return
                                    }
                                    
                                    if let floatVal = Float(newValue) {
                                        
                                        if let validHeadHeightRatio = headHeightRatio {
                                            let validHeadHeightRatioFloat = Float(validHeadHeightRatio)
                                            heightString = String(format: "%.2f", floatVal / validHeadHeightRatioFloat)
                                        }
                                        
                                    } else {
                                        print("unable to set Float(headHeightString)")
                                        headHeightString = ""
                                    }
                                }
                                .keyboardType(.decimalPad)
                            Text("x")
                            TextField("width (cm)", text: $headWidthString)
                                .focused($focusedField, equals: .headWidthField)
                                .onChange(of: headWidthString) { newValue in
                                    guard focusedField == .headWidthField else {
                                        return
                                    }
                                    if let floatVal = Float(newValue) {
                                        
                                        if let validHeadWidthRatio = headWidthRatio {
                                            let validHeadWidthRatioFloat = Float(validHeadWidthRatio)
                                            widthString = String(format: "%.2f", floatVal / validHeadWidthRatioFloat)
                                        }
                                        
                                    } else {
                                        headWidthString = ""
                                    }
                                }
                                .keyboardType(.decimalPad)
                            
                        }
                    }
                } // Dimensions Section
                .onAppear {
                    aspectRatio = image!.size.height / image!.size.width
                }
                .onChange(of: headHeightRatio) { newValue in
                    if let height = Float(heightString), let validHeadHeightRatio = newValue {
                        let totalHeightFloat = CGFloat(height)
                        headHeightString = String(format: "%.2f", validHeadHeightRatio * totalHeightFloat)
                    } else {
                        print("couldn't set height floats")
                        headHeightString = ""
                    }
                }
                .onChange(of: headWidthRatio) { newValue in
                    if let width = Float(widthString), let validHeadWidthRatio = newValue {
                        let totalWidthFloat = CGFloat(width)
                        headWidthString = String(format: "%.2f", validHeadWidthRatio * totalWidthFloat)
                    } else {
                        print("couldn't set width floats")
                        headWidthString = ""
                    }
                }
                
                
                // MARK: - looking direction
                if (isHead && !isBody) {
                    Section(header: Text("Looking Direction")) {
                        
                        HStack {
                            DirectionSelectorView(lookingDirection: $lookingDirection)
                                .onChange(of: lookingDirection) { newValue in
                                    lookingDirectionString = newValue?.rawValue ?? ""
                                    focusedField = nil
                                }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Looking:").bold()
                                Text("\(lookingDirectionString)")
                            }
                            .padding(.leading,30)
                            
                        }
                        
                    }
                    .onAppear {
                        if let lookingDirectionValue = LookingDirection(rawValue: lookingDirectionString) {
                            lookingDirection = lookingDirectionValue
                        }
                    }
                    
                }
                
                // MARK: - reset button
                Section {
                    Button {
                        resetData()
                    } label: {
                        Text("Clear Form")
                    }
                    
                    Button {
                        
                        print("coredata pressed")
                        // Clear HeadName data
                        let headNameFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "HeadName")
                        let headNameDeleteRequest = NSBatchDeleteRequest(fetchRequest: headNameFetchRequest)
                        
                        // Clear ClippingTag data
                        let clippingTagFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ClippingTag")
                        let clippingTagDeleteRequest = NSBatchDeleteRequest(fetchRequest: clippingTagFetchRequest)
                        
                        do {
                            try managedObjectContext.execute(headNameDeleteRequest)
                            try managedObjectContext.execute(clippingTagDeleteRequest)
                            try managedObjectContext.save()
                            print("Cleared existing HeadName and ClippingTag data")
                        } catch {
                            print("Error clearing CoreData: \(error)")
                        }
                        // set HeadName
                        var headNameCountDictionary: [String: Int] = [:]
                        
                        for clipping in sourceModel.clippings {
                            if (clipping.isHead && !clipping.isBody)  {
                                let headNameString = clipping.name
                                if let count = headNameCountDictionary[headNameString] {
                                    headNameCountDictionary[headNameString] = count + 1
                                } else {
                                    headNameCountDictionary[headNameString] = 1
                                }
                            }
                        }
                        print(headNameCountDictionary)
                        
                        for (name, count) in headNameCountDictionary {
                            let newHeadName = HeadName(context: self.managedObjectContext)
                            newHeadName.name = name
                            newHeadName.count = Int64(count)
                        }
                        
                        do {
                            try self.managedObjectContext.save()
                        } catch {
                            // handle the CoreDate error
                            print(error)
                        }
                        
                        
                        // set ClippingTag
                        var tagCountDictionary: [String: Int] = [:]
                        for clipping in sourceModel.clippings {
                            for tag in clipping.tags {
                                if let count = tagCountDictionary[tag] {
                                    tagCountDictionary[tag] = count + 1
                                } else {
                                    tagCountDictionary[tag] = 1
                                }
                            }
                        }
                        print(tagCountDictionary)
                        
                        for (tag, count) in tagCountDictionary {
                            let newTag = ClippingTag(context: self.managedObjectContext)
                            newTag.tagString = tag
                            newTag.count = Int64(count)
                        }
                        
                        do {
                            try self.managedObjectContext.save()
                        } catch {
                            print("Error saving ClippingTag data: \(error)")
                        }
                        
                    } label: {
                        Text("Set CoreData")
                    }
                }
                
                //MARK: - temporary button to reset Core Data
                //                Section {
                //                    Button {
                //                        let entitiesToClear = ["ClippingTag", "HeadName"]
                //
                //                        for entity in entitiesToClear {
                //                            print("clearing data for \(entity) entity")
                //                            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
                //                            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                //
                //                            do {
                //                                try managedObjectContext.execute(deleteRequest)
                //                                try managedObjectContext.save()
                //                            } catch let error as NSError {
                //                                print("Error: \(error.localizedDescription)")
                //                            }
                //                        }
                //                    } label: {
                //                        Text("Reset Core Data")
                //                    }
                //                }
                
            } // Form
            .toolbar {
                if [.totalHeightField, .totalWidthField, .headHeightField, .headWidthField].contains(focusedField) {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Cancel") {
                            if focusedField == .totalHeightField {
                                heightString = ""
                            }
                            endEditing()
                        }
                        Button("Enter") {
                            if focusedField == .totalHeightField {
                                if heightString.isEmpty || Double(heightString) != nil {
                                    focusedField = .totalWidthField
                                } else {
                                    handleMeasurementError()
                                }
                            }
                            
                            if focusedField == .totalWidthField {
                                if widthString.isEmpty || Double(widthString) != nil {
                                    if isHead && !isBody {
                                        focusedField = .headHeightField
                                    } else {
                                        focusedField = nil
                                        endEditing()
                                    }
                                } else {
                                    handleMeasurementError()
                                }
                            }
                            
                            if focusedField == .headHeightField {
                                if headHeightString.isEmpty || Double(headHeightString) != nil {
                                    focusedField = .headWidthField
                                } else {
                                    handleMeasurementError()
                                }
                            }
                            
                            if focusedField == .headWidthField {
                                if headWidthString.isEmpty || Double(headWidthString) != nil {
                                    focusedField = nil
                                    endEditing()
                                } else {
                                    handleMeasurementError()
                                }
                            }
                        }
                    } // ToolbarItemGroup
                }
            } // toolbar
            
            if focusedField == nil {
                HStack {
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 5)
                        .background(.clear)
                    VStack(alignment: .leading, spacing: 5) {
                        if source != nil {
                            Text(source!.title)
                            Text(source!.dateString)
                                .font(.subheadline)
                        }
                        if !name.isEmpty {
                            Text("Name: \(name)")
                        }
                    }.padding(.leading, 10)
                    Spacer()
                }.padding(.leading, 30)
                
                // MARK: - Add to Database button
                Button {
                    
                    guard !isSubmitting else { return } // prevent multiple accidental submissions
                    guard let source = source, let image = image else { return }
                    isSubmitting = true
                    
                    // get Source document from FireStore database
                    let docRef = sourcesCollection.document(source.id)
                    let tagsToSave = tags
                    let nameToSave = name
                    let shouldUpdateHeadName = isHead && !isBody
                    
                    docRef.getDocument { (documentSnapshot, error) in
                        if let error = error {
                            print("Error getting document: \(error)")
                            DispatchQueue.main.async {
                                isSubmitting = false
                                errorMessage = "Could not save to database: \(error.localizedDescription)"
                                activeAlert = .uploadError
                            }
                            return
                        }
                        
                        guard let documentSnapshot = documentSnapshot, documentSnapshot.exists else {
                            print("Document does not exist")
                            DispatchQueue.main.async {
                                isSubmitting = false
                                errorMessage = "The source document was not found. Please try again."
                                activeAlert = .uploadError
                            }
                            return
                        }
                        
                        // verified that Source document can be accessed
                        // now create Clipping entry
                        
                        let docName = UUID().uuidString
                        let imagePath = "clippingImages/\(docName).png"
                        let thumbPath = "clippingImages/\(docName)_thumb.png"
                        let midsizedPath = "clippingImages/\(docName)_mid.png"
                        
                        let newClipping = Clipping()
                        newClipping.id = docName
                        newClipping.sourceId = source.id
                        newClipping.isHead = isHead
                        newClipping.isBody = isBody
                        newClipping.isAnimal = isAnimal
                        newClipping.isMan = isMan
                        newClipping.isWoman = isWoman
                        newClipping.isTrans = isTrans
                        newClipping.isWhite = isWhite
                        newClipping.isBlack = isBlack
                        newClipping.isLatino = isLatino
                        newClipping.isAsian = isAsian
                        newClipping.isIndian = isIndian
                        newClipping.isNative = isNative
                        newClipping.isBlackAndWhite = isBW
                        newClipping.name = nameToSave
                        newClipping.tags = tagsToSave
                        newClipping.imageUrl = imagePath
                        newClipping.imageUrlMid = midsizedPath
                        newClipping.imageUrlThumb = thumbPath
                        newClipping.height = Double(heightString) ?? 0.0
                        newClipping.width = Double(widthString) ?? 0.0
                        if shouldUpdateHeadName {
                            newClipping.headHeight = Double(headHeightString)
                            newClipping.headWidth = Double(headWidthString)
                            newClipping.lookingDirection = lookingDirectionString
                        }
                        
                        guard let newClippingData = try? Firestore.Encoder().encode(newClipping) else {
                            DispatchQueue.main.async {
                                isSubmitting = false
                                errorMessage = "Could not encode clipping data. Please try again."
                                activeAlert = .uploadError
                            }
                            return
                        }
                        
                        // Upload images first so we never save a clipping with missing Storage files
                        let imageHelperFunctions = ImageHelperFunctions()
                        imageHelperFunctions.uploadClippingImages(image: image, docName: docName) { uploadResult in
                            switch uploadResult {
                            case .failure(let uploadError):
                                DispatchQueue.main.async {
                                    isSubmitting = false
                                    errorMessage = uploadError.localizedDescription
                                    activeAlert = .uploadError
                                }
                                
                            case .success:
                                docRef.updateData(["clippings": FieldValue.arrayUnion([newClippingData])]) { writeError in
                                    DispatchQueue.main.async {
                                        if let writeError {
                                            isSubmitting = false
                                            errorMessage = "Images uploaded, but saving failed: \(writeError.localizedDescription)"
                                            activeAlert = .uploadError
                                            return
                                        }
                                        
                                        self.updateCoreDataAfterClippingSave(
                                            tags: tagsToSave,
                                            name: nameToSave,
                                            shouldUpdateHeadName: shouldUpdateHeadName
                                        )
                                        
                                        isAdded = true
                                        isSubmitting = false
                                        lastSourceId = source.id
                                        activeAlert = .success
                                    }
                                }
                            }
                        }
                    } // docRef.getDocument
                    
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text("Add to Database")
                    }
                }
                .disabled(!isFormComplete || isAdded || isSubmitting)
                .buttonStyle(ButtonStyle1(inputColor: (isFormComplete && !isAdded && !isSubmitting) ? .blue : .gray))
                .padding(.bottom, 30)
                .padding(.top, 10)
                .padding(.horizontal, 40)
            } // conditional display of thumbnail and submit button
            
        } // VStack
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .success:
                return Alert(title: Text("Database item successfully added"),
                             message: nil,
                             dismissButton: .default(Text("Ok"), action: {
                    resetData()
                    sourceModel.updateSources()
                    presentationMode.wrappedValue.dismiss()
                }))
            case .measureError:
                return Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            case .uploadError:
                return Alert(title: Text("Upload failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        } // alert
        
        
    } // body View
    
    private func updateCoreDataAfterClippingSave(tags: [String], name: String, shouldUpdateHeadName: Bool) {
        for tag in tags {
            let fetchRequest: NSFetchRequest<ClippingTag> = ClippingTag.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "tagString = %@", tag)
            
            do {
                let matchingTags = try managedObjectContext.fetch(fetchRequest)
                if let existingTag = matchingTags.first {
                    existingTag.count += 1
                } else {
                    let newTag = ClippingTag(context: managedObjectContext)
                    newTag.tagString = tag
                    newTag.count = 1
                    print("adding new '\(tag)' ClippingTag entity to CoreData")
                }
            } catch {
                print("Failed to fetch tag from CoreData: \(error)")
            }
        }
        
        if shouldUpdateHeadName {
            let fetchRequest: NSFetchRequest<HeadName> = HeadName.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name = %@", name)
            
            do {
                let matchingHead = try managedObjectContext.fetch(fetchRequest)
                if let existingHead = matchingHead.first {
                    existingHead.count += 1
                } else {
                    let newHead = HeadName(context: managedObjectContext)
                    newHead.name = name
                    newHead.count = 1
                    print("adding new '\(name)' HeadName entity to CoreData")
                }
            } catch {
                print("Failed to fetch head name from CoreData: \(error)")
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func handleMeasurementError() {
        errorMessage = "Invalid measurement. Please enter a valid number."
        activeAlert = .measureError
        //showAlert = true
    }
    
    private func resetData() {
        isHead = false
        isBody = false
        isAnimal = false
        isMan = false
        isWoman = false
        isTrans = false
        isWhite = false
        isBlack = false
        isLatino = false
        isAsian = false
        isIndian = false
        isNative = false
        isBW = false
        sourceSearch = ""
        source = nil
        name = ""
        heightString = ""
        widthString = ""
        headHeightString = ""
        headWidthString = ""
        tags = []
        singleTag = ""
        focusedField = nil
        lookingDirectionString = ""
        lookingDirection = nil
        UserDefaults.standard.removeObject(forKey: "tags")
        isAdded = false
    }
    
    
    //    func fetchCelebrityData(image: UIImage, completion: @escaping (Result<JSON, Error>) -> Void) {
    //        // Replace `your-rapidapi-key` with your actual RapidAPI key
    //        let headers: HTTPHeaders = [
    //            "X-RapidAPI-Host": "celebrities-face-recognition.p.rapidapi.com",
    //            "X-RapidAPI-Key": "your-rapidapi-key"
    //        ]
    //
    //        let url = "https://celebrities-face-recognition.p.rapidapi.com/recognize"
    //
    //        AF.upload(multipartFormData: { multipartFormData in
    //            if let imageData = image.jpegData(compressionQuality: 0.9) {
    //                multipartFormData.append(imageData, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    //            }
    //        }, to: url, headers: headers)
    //        .validate()
    //        .responseJSON { response in
    //            switch response.result {
    //            case .success(let value):
    //                let json = JSON(value)
    //                completion(.success(json))
    //            case .failure(let error):
    //                completion(.failure(error))
    //            }
    //        }
    //    }
    
}

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
}

//struct AddClippingView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            AddClippingView(image: UIImage(named: "Anna_2"))
//                .environmentObject(SourceModel())
//                .environmentObject(NavigationStateManager())
//        }
//    }
//}
