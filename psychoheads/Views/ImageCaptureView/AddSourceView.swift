//
//  AddSourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/27/25.
//


//
//  AddSourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/24/23.
//

import UIKit
import SwiftUI
import FirebaseFirestore
import CoreData

struct AddSourceView: View {
    
    enum Field: Hashable {
        case titleField
        case monthField
        case issueField
    }
    
    enum ActiveAlert: Identifiable {
        case success, duplicate, uploadError
        
        var id: Int {
            switch self {
            case .success:
                return 1
            case .duplicate:
                return 2
            case .uploadError:
                return 3
            }
        }
    }
    
    @EnvironmentObject var sourceModel: SourceModel
    
    let image: UIImage?
    @AppStorage("sourceType") private var sourceType: String = ""
    let sourceOptions = ["","Magazine","Book","Other"]
    private let monthSuggestions = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
        "Spring", "Summer", "Fall", "Autumn", "Winter"
    ]
    @AppStorage("sourceTitle") private var sourceTitle: String = ""
    @AppStorage("nCopies") private var nCopies: Int = 1
    @AppStorage("sourceYear") private var sourceYear: String = ""
    @AppStorage("sourceMonth") private var sourceMonth: String = ""
    @AppStorage("sourceDate") private var sourceDay: String = ""
    @AppStorage("sourceIssue") private var sourceIssue: String = ""
    
    @FocusState private var focusedField: Field?
    @State private var isTitleFieldActive: Bool = false
    @State private var isMonthFieldActive: Bool = false
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: SourceName.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \SourceName.count, ascending: false)]) var sourceNames: FetchedResults<SourceName>
    
    var existingSourceNames: [String] {
        let sources = sourceNames.map { $0.nameString ?? "" }
        print("Number of existing sources: \(sources.count)")
        
        for sourceName in sourceNames {
            if let sourceNameString = sourceName.nameString {
                print("   sourceName: \(sourceNameString), Count: \(sourceName.count)")
            }
        }
        return sources
    }
    
    /// Static months/seasons plus distinct non-empty month values already used on sources.
    private var allMonthSuggestions: [String] {
        var seen = Set(monthSuggestions.map { $0.lowercased() })
        var result = monthSuggestions
        for source in sourceModel.sources {
            let month = (source.month ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !month.isEmpty else { continue }
            let key = month.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                result.append(month)
            }
        }
        return result
    }
    
    let constants = Constants()
    private var isFormComplete: Bool {
        return !sourceTitle.isEmpty && !sourceType.isEmpty && !sourceYear.isEmpty
    }
    @State private var isPressed = false
    @State private var isAdded = false
    @State private var isSubmitting = false
    @Environment(\.presentationMode) var presentationMode
    @State private var activeAlert: ActiveAlert? = nil
    @State private var errorMessage: String = ""
    
    var body: some View{
        
        let db = Firestore.firestore()
        let sourcesCollection = db.collection("sources")
        
        ZStack {
            Color.clear
            VStack {
                Text("Add Source Info")
                    .padding(.top)
                
                Form {
                    
                    //Toggle("Magazine", isOn: $isMag)
                    Picker("Source Type", selection: $sourceType) {
                        ForEach(sourceOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    
                    // MARK: - source Title
                    TextField("Title", text: $sourceTitle)
                        .onSubmit {
                            sourceTitle = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .focused($focusedField, equals: .titleField)
                        .onChange(of: focusedField) { newValue in
                            isTitleFieldActive = (newValue == .titleField)
                            isMonthFieldActive = (newValue == .monthField)
                        }
                    
                    let sortedTitleNames = existingSourceNames.filter({ sourceText in sourceTitle == "" ? true : sourceText.lowercased().contains(sourceTitle.lowercased())})
                    
                    if (isTitleFieldActive && !sortedTitleNames.isEmpty) {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(sortedTitleNames, id: \.self) { titleName in
                                    TagView2(tag: titleName) {
                                        sourceTitle = titleName
                                        focusedField = nil
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    let yearList = [""] + (1969...constants.getCurrentYear()).reversed().map(String.init)
                    Picker("Year", selection: $sourceYear) {
                        ForEach(yearList, id: \.self) { val in
                            Text(val)
                        }
                    }
                    
                    TextField("Month/Season", text: $sourceMonth)
                        .onSubmit {
                            sourceMonth = sourceMonth.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .focused($focusedField, equals: .monthField)
                    
                    let sortedMonthSuggestions = allMonthSuggestions.filter {
                        sourceMonth.isEmpty || $0.lowercased().contains(sourceMonth.lowercased())
                    }
                    
                    if isMonthFieldActive && !sortedMonthSuggestions.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(sortedMonthSuggestions, id: \.self) { monthName in
                                    TagView2(tag: monthName) {
                                        sourceMonth = monthName
                                        focusedField = nil
                                    }
                                }
                            }
                        }
                    }
                    
                    let dateList = [""] + (1...31).map(String.init)
                    Picker("Date", selection: $sourceDay) {
                        ForEach(dateList, id: \.self) { val in
                            Text(val)
                        }
                    }
                    
                    TextField("Issue", text: $sourceIssue)
                        .onSubmit {
                            sourceIssue = sourceIssue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .focused($focusedField, equals: .issueField)
                    
                    Picker("Number of copies", selection: $nCopies) {
                        ForEach(1...20, id: \.self) {
                            Text(String($0))
                        }
                    }
                    
                    Section {
                        Button {
                            resetData()
                            print("clear form in Source Info pressed")
                        } label: {
                            Text("Clear Form")
                        }
                        
                        Button {
                            print("coredata pressed")
                            var sourceNameCountDictionary: [String: Int] = [:]
                            for source in sourceModel.sources {
                                let title = source.title
                                if let count = sourceNameCountDictionary[title] {
                                    sourceNameCountDictionary[title] = count + 1
                                } else {
                                    sourceNameCountDictionary[title] = 1
                                }
                            }
                            print(sourceNameCountDictionary)
                            
                            for (name, count) in sourceNameCountDictionary {
                                let newSourceName = SourceName(context: self.managedObjectContext)
                                newSourceName.nameString = name
                                newSourceName.count = Int64(count)
                            }

                            do {
                                try self.managedObjectContext.save()
                            } catch {
                                // handle the Core Data error
                                print(error)
                            }
                            
                        } label: {
                            Text("Set CoreData")
                        }
                    }
                    
                } // Form

                
// MARK: - Source image and Add button

                if focusedField == nil {
                    
                    HStack {
                        Image(uiImage: image!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.top, 5)
                            .background(.clear)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(sourceType)").bold()
                            Text("Title: \(sourceTitle)")
                            if !sourceMonth.isEmpty {
                                Text("Month/Season: \(sourceMonth)")
                            }
                            if !sourceDay.isEmpty {
                                Text("Date: \(sourceDay)")
                            }
                            Text("Year: "+String(sourceYear))
                            if !sourceIssue.isEmpty {
                                Text("Issue: \(sourceIssue)")
                            }
                            Text("Number of Copies: \(nCopies)")
                        }.padding(.leading, 10)
                        Spacer()
                    }.padding(.leading, 30)
                    
                    
                    // MARK: - button to add new source data
                    Button {
                        guard !isSubmitting else { return } // prevent accidental double-submits
                        isSubmitting = true
                        
                        sourceTitle = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        sourceMonth = sourceMonth.trimmingCharacters(in: .whitespacesAndNewlines)
                        sourceIssue = sourceIssue.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // TODO: refactor to move most of this to DatabaseFunctions
                        // create array of document fields and values
                        var fieldDict = ["sourcetype": sourceType,
                                         "title": sourceTitle,
                                         "year": sourceYear]
                        if !sourceMonth.isEmpty {
                            fieldDict["month"] = sourceMonth
                        }
                        if !sourceDay.isEmpty {
                            fieldDict["day"] = sourceDay
                        }
                        if !sourceIssue.isEmpty {
                            fieldDict["issue"] = sourceIssue
                        }
                        print(fieldDict)
                        
                        print("checking for duplicate document")
                        var query: Query = sourcesCollection
                        for (field, value) in fieldDict {
                            query = query.whereField(field, isEqualTo: value)
                        }
                        
                        query.getDocuments { (querySnapshot, error) in
                            if let error = error {
                                print("error getting document from database: \(error)")
                                DispatchQueue.main.async {
                                    isSubmitting = false
                                    errorMessage = "Could not save to database: \(error.localizedDescription)"
                                    activeAlert = .uploadError
                                }
                                return
                            }
                            
                            guard let querySnapshot = querySnapshot else {
                                DispatchQueue.main.async {
                                    isSubmitting = false
                                    errorMessage = "Could not check for duplicates. Please try again."
                                    activeAlert = .uploadError
                                }
                                return
                            }
                            
                            // if matches found, treat as duplicate
                            if querySnapshot.documents.count > 0 {
                                DispatchQueue.main.async {
                                    activeAlert = .duplicate
                                    isSubmitting = false
                                }
                                return
                            }
                            
                            guard let image = image else {
                                DispatchQueue.main.async {
                                    isSubmitting = false
                                    errorMessage = "No image available to upload."
                                    activeAlert = .uploadError
                                }
                                return
                            }
                            
                            let docName = UUID().uuidString
                            let imagePath = "sourceImages/\(docName).png"
                            let thumbPath = "sourceImages/\(docName)_thumb.png"
                            let midsizedPath = "sourceImages/\(docName)_mid.png"
                            print("docName = \(docName)")
                            
                            var data: [String: Any] = [
                                "sourcetype": sourceType,
                                "title": sourceTitle,
                                "year": sourceYear,
                                "copies": nCopies,
                                "timeadded": constants.now,
                                "imagelocation": imagePath,
                                "midsizedlocation": midsizedPath,
                                "thumblocation": thumbPath
                            ]
                            if !sourceMonth.isEmpty {
                                data["month"] = sourceMonth
                            }
                            if !sourceDay.isEmpty {
                                data["day"] = sourceDay
                            }
                            if !sourceIssue.isEmpty {
                                data["issue"] = sourceIssue
                            }
                            
                            // Upload images first so we never save a source with missing Storage files
                            let imageHelperFunctions = ImageHelperFunctions()
                            imageHelperFunctions.uploadSourceImages(image: image, docName: docName) { uploadResult in
                                switch uploadResult {
                                case .failure(let uploadError):
                                    DispatchQueue.main.async {
                                        isSubmitting = false
                                        errorMessage = uploadError.localizedDescription
                                        activeAlert = .uploadError
                                    }
                                    
                                case .success:
                                    let newDoc = sourcesCollection.document(docName)
                                    newDoc.setData(data) { writeError in
                                        DispatchQueue.main.async {
                                            if let writeError {
                                                isSubmitting = false
                                                errorMessage = "Images uploaded, but saving failed: \(writeError.localizedDescription)"
                                                activeAlert = .uploadError
                                                return
                                            }
                                            
                                            self.updateCoreDataAfterSourceSave(title: sourceTitle)
                                            
                                            isAdded = true
                                            sourceModel.updateSources()
                                            activeAlert = .success
                                            isSubmitting = false
                                        }
                                    }
                                }
                            }
                        } // getDocuments query
                        
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
                    .buttonStyle(ButtonStyle1(inputColor: isFormComplete && !isAdded && !isSubmitting ? .blue : .gray))
                    .padding(.bottom, 30)
                    .padding(.horizontal,40)
                    
                } // end conditional display of image and Add button
                
            } // VStack
            .background(.clear)
            
        } // ZStack
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .success:
                return Alert(title: Text("Database item successfully added"),
                             message: nil,
                             dismissButton: .default(Text("Ok"), action: {
                    resetData()
                    presentationMode.wrappedValue.dismiss()
                }))
            case .duplicate:
                return Alert(title: Text("Duplicate Item"),
                             message: Text("Increment number of copies?"),
                             primaryButton: .default(Text("Increment"), action: {
                            // TODO: function call to increment number of copies
                }),
                             secondaryButton: .cancel(Text("Dismiss"))
                )
            case .uploadError:
                return Alert(title: Text("Upload failed"),
                             message: Text(errorMessage),
                             dismissButton: .default(Text("OK")))
            }
        } // end alert
        
    } // body view
            
//    private func saveFormData() {
//        UserDefaults.standard.set(sourceType, forKey: "sourceType")
//        UserDefaults.standard.set(sourceTitle, forKey: "sourceTitle")
//        UserDefaults.standard.set(sourceYear, forKey: "sourceYear")
//        UserDefaults.standard.set(sourceMonth, forKey: "sourceMonth")
//        UserDefaults.standard.set(sourceDay, forKey: "sourceDay")
//        UserDefaults.standard.set(sourceIssue, forKey: "sourceIssue")
//        UserDefaults.standard.set(nCopies, forKey: "nCopies")
//    }
//
//    private func loadFormData() {
//        sourceType = UserDefaults.standard.string(forKey: "sourceType") ?? ""
//        sourceTitle = UserDefaults.standard.string(forKey: "sourceTitle") ?? ""
//        sourceYear = UserDefaults.standard.string(forKey: "sourceYear") ?? ""
//        sourceMonth = UserDefaults.standard.string(forKey: "sourceMonth") ?? ""
//        sourceDay = UserDefaults.standard.string(forKey: "sourceDay") ?? ""
//        sourceIssue = UserDefaults.standard.string(forKey: "sourceIssue") ?? ""
//        nCopies = UserDefaults.standard.integer(forKey: "nCopies")
//    }
    
    private func updateCoreDataAfterSourceSave(title: String) {
        let fetchRequest: NSFetchRequest<SourceName> = SourceName.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "nameString == %@", title)
        do {
            let matchingSourceNames = try managedObjectContext.fetch(fetchRequest)
            if let existingSourceName = matchingSourceNames.first {
                existingSourceName.count += 1
            } else {
                let newSourceName = SourceName(context: managedObjectContext)
                newSourceName.nameString = title
                newSourceName.count = 1
            }
            try managedObjectContext.save()
        } catch {
            print(error)
        }
    }
    
    private func resetData() {
        sourceType = ""
        sourceTitle = ""
        sourceYear = ""
        sourceMonth = ""
        sourceDay = ""
        sourceIssue = ""
        nCopies = 1
    }
    
}

//struct AddSourceView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddSourceView(image: UIImage(named: "mag_1"))
//    }
//}
