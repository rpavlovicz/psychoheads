//
//  SourceModel.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 3/30/23.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import CoreData

enum SourceCoverageFilter: String, CaseIterable, Identifiable, Codable, Hashable {
    case withClippings
    case all
    case unclippedOnly
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .withClippings:
            return "With Clippings"
        case .all:
            return "All Sources"
        case .unclippedOnly:
            return "Unclipped Only"
        }
    }
}

class SourceModel: ObservableObject {
    
    @Published var clippings: [Clipping] = []
    @Published var sources = [Source]()
    @Published var currentHeadClippings: [Clipping] = [] // An array of random head clippings
    @Published var currentClippingIndex: Int = 0 // Track which clipping is being displayed

    let db = Firestore.firestore()
    
    // Computed property to get all head clippings
    var headClippings: [Clipping] {
        clippings.filter { $0.isHead && !$0.isBody }
    }
        
    init() {
        getSources()
        loadRandomHeadClippings()
    }
    
    func getSources() {
        // initial population of sources SourceModel
        let collection = db.collection("sources")
        collection.getDocuments { snapshot, error in
            
            if error == nil && snapshot != nil {
            
                var sources = [Source]()
                
                for doc in snapshot!.documents {
                    
                    let s = Source()
                    
                    s.id = doc.documentID
                    s.type = doc["sourcetype"] as? String ?? doc["type"] as? String ?? ""
                    s.title = doc["title"] as? String ?? ""
                    s.year = doc["year"] as? String ?? ""
                    s.month = doc["month"] as? String ?? ""
                    s.day = doc["day"] as? String ?? ""
                    s.issue = doc["issue"] as? String ?? ""
                    s.ncopies = doc["copies"] as? Int ?? 0
                    s.imageUrl = doc["imagelocation"] as? String ?? ""
                    s.imageUrlMid = doc["midsizedlocation"] as? String ?? ""
                    s.imageUrlThumb = doc["thumblocation"] as? String ?? ""
                    
                    if let timestamp = doc["timeadded"] as? Timestamp {
                        s.added = timestamp.dateValue()
                    } else {
                        s.added = Date()
                    }
                    
                    // TODO: important!!!! finish loading all clipping attributes!
                    
                    if let clippingDicts = doc["clippings"] as? [[String: Any]] {
                        for dict in clippingDicts {
                            let clipping = self.createClippingFromDict(dict)
                            s.clippings.append(clipping)
                        }
                    }

                    sources.append(s)
                    
                }
                
                DispatchQueue.main.async {
                    self.sources = sources
                    self.clippings = sources.flatMap { $0.clippings }
                    print("Sources loaded: \(self.sources.count)")
                    print("Total clippings loaded: \(self.clippings.count)")
                    print("Head clippings count: \(self.headClippings.count)")
                }
            }
        }
    } // end getSources()

    func getSourceFromID(id: String) -> Source? {
        return sources.first { $0.id == id }
    }
    
    func aggregatedTagsForName(_ name: String) -> [String] {
        // Aggregate all clippings with the given name across all sources
        let matchingClippings = sources.flatMap { $0.clippings }.filter { $0.name == name }

        let numberOfClippings = matchingClippings.count
        
        // Aggregate and count tags from these clippings
        var tagCounts = [String: Int]()
        for clipping in matchingClippings {
            for tag in clipping.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        print("number of clippings = \(numberOfClippings)")
        print("unfiltered number of tags = \(tagCounts.count)")
        let sortedTagCounts = tagCounts.sorted { $0.value > $1.value }
        for (tag, count) in sortedTagCounts{
            print("Tag: \(tag) , Count: \(count)")
        }
        
        // Sort tags by frequency
        let minimumOccurence = max(0, numberOfClippings / 2)
        print("minimumOccurenct = \(minimumOccurence)")
        
        let sortedTags = tagCounts.filter { $0.value >= minimumOccurence }
                                  .sorted { $0.value > $1.value }
                                  .map { $0.key }
        
        print("filtered number of tags = \(sortedTags.count)")
        return sortedTags
    }
    
    func createSourceFromClippingName(clippingName: String) -> Source {
        let newSource = Source(title:clippingName)
        
        for source in self.sources {
            let clippingsWithMatchingName = source.clippings.filter { $0.name == clippingName }
            newSource.clippings.append(contentsOf: clippingsWithMatchingName)
        }
        
        return newSource
    }
    
    // this function only adds new sources to the SourceModel
    // does not check for changes in individual Sources
    func updateSources() {
        // upodate sources SourceModel
        let collection = db.collection("sources")
        collection.getDocuments { snapshot, error in
            if error == nil && snapshot != nil {
                var newSources = [Source]()
                for doc in snapshot!.documents {
                    let id = doc.documentID
                    // search for new ids. if found, add to newSources
                    if !self.sources.contains(where: { $0.id == id}) {
                        let s = Source()
                        s.id = doc.documentID
                        s.type = doc["sourcetype"] as? String ?? ""
                        s.title = doc["title"] as? String ?? ""
                        s.year = doc["year"] as? String ?? ""
                        s.month = doc["month"] as? String ?? ""
                        s.day = doc["day"] as? String ?? ""
                        s.issue = doc["issue"] as? String ?? ""
                        s.ncopies = doc["copies"] as? Int ?? 0
                        s.clippings = doc["clippings"] as? [Clipping] ?? []
                        s.imageUrl = doc["imagelocation"] as? String ?? ""
                        s.imageUrlMid = doc["midsizedlocation"] as? String ?? ""
                        s.imageUrlThumb = doc["thumblocation"] as? String ?? ""
                        
                        if let timestamp = doc["timeadded"] as? Timestamp {
                            s.added = timestamp.dateValue()
                        } else {
                            s.added = Date()
                        }
                        
                        if let clippingDicts = doc["clippings"] as? [[String: Any]] {
                            for dict in clippingDicts {
                                let clipping = self.createClippingFromDict(dict)
                                s.clippings.append(clipping)
                            }
                        }
                        
                        newSources.append(s)
                    } // end if case for newly identified source.id
                    
                    if let existingSourceIndex = self.sources.firstIndex(where: { $0.id == id}) {
                        // source is already present, but check if number of clippings has changed
                        if let clippings = doc["clippings"] as? [[String: Any]],
                           self.sources[existingSourceIndex].clippings.count != clippings.count {
                            var newClippings = [Clipping]()
                            for clippingDict in clippings {
                                let clipping = self.createClippingFromDict(clippingDict)
                                newClippings.append(clipping)
                            }
                            DispatchQueue.main.async {
                                self.sources[existingSourceIndex].clippings = newClippings
                            }
                        }
                    } // end if found exising source
                } // end for loop going through all sources
                
                // append newSources to existing sources object
                DispatchQueue.main.async {
                    self.sources.append(contentsOf: newSources)
                }
            }
            
        }
    } // end updateSources
        
    // MARK: - update single source
    func updateSource(_ source: Source, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("sources").document(source.id)
        
        // First, convert clippings to dictionary format for Firestore
        let clippingDicts = source.clippings.map { clipping -> [String: Any] in
            // Create a dictionary that mirrors the structure of your Clipping class.
            // All fields should be included here.
            // Add more fields if your Clipping class has more properties.
            return [
                "id": clipping.id,
                "sourceId": clipping.sourceId,
                "headHeight": clipping.headHeight ?? NSNull(),
                "headWidth": clipping.headWidth ?? NSNull(),
                "height": clipping.height,
                "width": clipping.width,
                "imageUrl": clipping.imageUrl,
                "imageUrlMid": clipping.imageUrlMid,
                "imageUrlThumb": clipping.imageUrlThumb,
                "isHead": clipping.isHead,
                "isBody": clipping.isBody,
                "isAnimal": clipping.isAnimal,
                "isMan": clipping.isMan,
                "isWoman": clipping.isWoman,
                "isTrans": clipping.isTrans,
                "isWhite": clipping.isWhite,
                "isBlack": clipping.isBlack,
                "isLatino": clipping.isLatino,
                "isAsian": clipping.isAsian,
                "isIndian": clipping.isIndian,
                "isNative": clipping.isNative,
                "isBlackAndWhite": clipping.isBlackAndWhite,
                "name": clipping.name,
                "lookingDirection": clipping.lookingDirection ?? "",
                "tags": clipping.tags,
                "added": clipping.added
            ]
        }
        
        docRef.updateData([
            "title": source.title,
            "type": source.type,
            "year": source.year,
            "month": source.month ?? "",
            "day": source.day ?? "",
            "issue": source.issue ?? "",
            "copies": source.ncopies,
            "thumblocation": source.imageUrlThumb,
            "clippings": clippingDicts
        ]) { error in
            if let error = error {
                print("Error updating source: \(error)")
                completion(false)
            } else {
                print("Source successfully updated")
                completion(true)
                // You might also want to update the source in your local `sources` array.
                // This way, your UI will show the updated source.
                if let index = self.sources.firstIndex(where: { $0.id == source.id }) {
                    DispatchQueue.main.async {
                        self.sources[index] = source
                    }
                }
            }
        }
    }

    func deleteSource(_ source: Source) {
        // Delete the source from Firebase
        db.collection("sources").document(source.id).delete { error in
            
            if let error = error {
                print("Error deleting source: \(error)")
            } else {
                // Remove the source from the sources array
                if let index = self.sources.firstIndex(where: { $0.id == source.id }) {
                    DispatchQueue.main.async {
                        self.sources.remove(at: index)
                    }
                }
            }
        }
        
        // Delete corresponding images from Firestore
        let storage = Storage.storage()
        
        let mainImagePath = "sourceImages/\(source.id).png"
        let midPath = "sourceImages/\(source.id)_mid.png"
        let thumbnailPath = "sourceImages/\(source.id)_thumb.png"
        
        let imagePaths = [mainImagePath, midPath, thumbnailPath]
        
        for path in imagePaths {
            let imageRef = storage.reference().child(path)
            imageRef.delete { error in
                if let error = error {
                    print("Error deleting image at path '\(path)': \(error)")
                } else {
                    print("Successfully deleted image at path '\(path)'")
                }
            }
        }
        
    } // end deleteSource
    
    // TODO: move this to database functions?
    // TODO: this is not reflecting database changes to the Source or SourceModel objects
    func editSource(_ source: Source) {
        let docRef = db.collection("sources").document(source.id)
        
        docRef.updateData([
            "title": source.title,
            "type": source.type,
            "year": source.year,
            "month": source.month ?? "",
            "issue": source.issue ?? "",
            "day": source.day ?? "",
            "copies": source.ncopies
        ]) { error in
            if let error = error {
                print("Error updating source: \(error)")
            } else {
                print("Source successfuly updated")
            }
        }
    } // end editSource
    
    func createClippingFromDict(_ dict: [String: Any]) -> Clipping {
        let clipping = Clipping()
        clipping.id = dict["id"] as? String ?? ""
        clipping.sourceId = dict["sourceId"] as? String ?? ""
        clipping.headHeight = dict["headHeight"] as? Double ?? nil
        clipping.headWidth = dict["headWidth"] as? Double ?? nil
        clipping.height = dict["height"] as? Double ?? 0.0
        clipping.width = dict["width"] as? Double ?? 0.0
        clipping.imageUrl = dict["imageUrl"] as? String ?? ""
        clipping.imageUrlMid = dict["imageUrlMid"] as? String ?? ""
        clipping.imageUrlThumb = dict["imageUrlThumb"] as? String ?? ""
        clipping.isHead = dict["isHead"] as? Bool ?? false
        clipping.isBody = dict["isBody"] as? Bool ?? false
        clipping.isAnimal = dict["isAnimal"] as? Bool ?? false
        clipping.isMan = dict["isMan"] as? Bool ?? false
        clipping.isWoman = dict["isWoman"] as? Bool ?? false
        clipping.isTrans = dict["isTrans"] as? Bool ?? false
        clipping.isWhite = dict["isWhite"] as? Bool ?? false
        clipping.isBlack = dict["isBlack"] as? Bool ?? false
        clipping.isLatino = dict["isLatino"] as? Bool ?? false
        clipping.isAsian = dict["isAsian"] as? Bool ?? false
        clipping.isIndian = dict["isIndian"] as? Bool ?? false
        clipping.isNative = dict["isNative"] as? Bool ?? false
        clipping.isBlackAndWhite = dict["isBlackAndWhite"] as? Bool ?? false
        clipping.name = dict["name"] as? String ?? ""
        clipping.lookingDirection = dict["lookingDirection"] as? String ?? ""

        if let tags = dict["tags"] as? [String] {
            clipping.tags = tags
        }

        if let timestamp = dict["added"] as? Timestamp {
            clipping.added = timestamp.dateValue()
        } else {
            clipping.added = Date()
        }

        return clipping
    }
    
    func deleteClipping(_ clipping: Clipping) {
        // deleteClipping from FireStore database from SourceModel
        
        guard !clipping.sourceId.isEmpty else {
            print("Error: Cannot delete clipping because sourceId is empty")
            return
        }
        
        // Delete the clipping from Firebase
        let sourceRef = db.collection("sources").document(clipping.sourceId)
        sourceRef.getDocument { DocumentSnapshot, error in
            if let document = DocumentSnapshot {
                var clippings = document.get("clippings") as? [[String: Any]] ?? []
                if let index = clippings.firstIndex(where: { $0["id"] as? String == clipping.id }) {
                    clippings.remove(at: index)
                    sourceRef.updateData([
                        "clippings": clippings
                    ]) { error in
                        if let error = error {
                            print("Error updating clippings: \(error)")
                        } else {
                            print("Successfully removed clipping with id \(clipping.id) from source with id \(clipping.sourceId)")
                            if let sourceIndex = self.sources.firstIndex(where: { $0.id == clipping.sourceId}),
                               let clippingIndex = self.sources[sourceIndex].clippings.firstIndex(where: { $0.id == clipping.id }) {
                                DispatchQueue.main.async {
                                    self.sources[sourceIndex].clippings.remove(at: clippingIndex)
                                }
                            }
                        }
                    }
                }
            } else if  let error = error {
                print("Error getting document: \(error)")
            }
        }
        
        // Delete corresponding images from Firestore
        let storage = Storage.storage()
        
        let mainImagePath = clipping.imageUrl
        let midPath = clipping.imageUrlMid
        let thumbnailPath = clipping.imageUrlThumb
        
        let imagePaths = [mainImagePath, midPath, thumbnailPath]
        
        for path in imagePaths {
            let imageRef = storage.reference().child(path)
            imageRef.delete { error in
                if let error = error {
                    print("Error deleting image at path '\(path)': \(error)")
                } else {
                    print("Successfully deleted image at path '\(path)'")
                }
            }
        }
        
    } // end deleteClipping
    
    func updateClipping(_ clipping: Clipping, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("sources").document(clipping.sourceId)

        docRef.getDocument { documentSnapshot, error in
            
            if let error = error {
                print("Error fetching document: \(error)")
                completion(false)
                return
            }
            
            guard let document = documentSnapshot, document.exists, var clippings = document.data()?["clippings"] as? [[String: Any]] else {
                print("Document or clippings array not found")
                completion(false)
                return
            }
            
            // Find the index of the clipping to update
            if let index = clippings.firstIndex(where: { $0["id"] as? String == clipping.id }) {
                // Update the clipping at the found index
                let updatedClippingData: [String:Any] = [
                    "id": clipping.id,
                    "sourceId": clipping.sourceId,
                    "name": clipping.name,
                    "tags": clipping.tags,
                    "isHead": clipping.isHead,
                    "isBody": clipping.isBody,
                    "isAnimal": clipping.isAnimal,
                    "isMan": clipping.isMan,
                    "isWoman": clipping.isWoman,
                    "isTrans": clipping.isTrans,
                    "isWhite": clipping.isWhite,
                    "isBlack": clipping.isBlack,
                    "isLatino": clipping.isLatino,
                    "isAsian": clipping.isAsian,
                    "isIndian": clipping.isIndian,
                    "isNative": clipping.isNative,
                    "isBlackAndWhite": clipping.isBlackAndWhite,
                    "width": clipping.width,
                    "height": clipping.height,
                    "headWidth": clipping.headWidth ?? NSNull(), // Use NSNull for optional nil values
                    "headHeight": clipping.headHeight ?? NSNull(),
                    "lookingDirection": clipping.lookingDirection ?? NSNull(),
                    "added": Timestamp(date: clipping.added),
                    "imageUrl": clipping.imageUrl,
                    "imageUrlMid": clipping.imageUrlMid,
                    "imageUrlThumb": clipping.imageUrlThumb
                ]
                
                clippings[index] = updatedClippingData
                
                print("updating clipping at index \(index) with name \(clipping.name)")
                
                // Update the entire clippings array in Firestore
                docRef.updateData(["clippings": clippings]) { error in
                    if let error = error {
                        print("Error updating clippings array: \(error)")
                        completion(false)
                    } else {
                        // Now update the local data
                        if let sourceIndex = self.sources.firstIndex(where: { $0.id == clipping.sourceId }) {
                            if let clippingIndex = self.sources[sourceIndex].clippings.firstIndex(where: { $0.id == clipping.id }) {
                                DispatchQueue.main.async {
                                    self.sources[sourceIndex].clippings[clippingIndex] = clipping
                                    self.clippings = self.sources.flatMap { $0.clippings }
                                    completion(true)
                                    print("Clippings array successfully updated")
                                }
                            }
                        }

                    }
                }
                
            } else {
                print("Clipping not found in array")
                completion(false)
            }
            
        } // end getDocument

    } // end updateClipping
    
    // Method to load a random head clipping
    func loadRandomHeadClippings(batchSize: Int = 5) {
        let allHeadClippings = headClippings
        print("All head clippings count: \(allHeadClippings.count)")
        guard !allHeadClippings.isEmpty else {
            print("No head clippings found")
            return
        }
        
        currentHeadClippings = Array(allHeadClippings.shuffled().prefix(batchSize))
        currentClippingIndex = 0
        print("Loaded batch of random head clippings")
    }
    
    // Get the next head clipping and append a new random one in the background
    func getNextHeadClipping() {
        if currentClippingIndex + 1 < currentHeadClippings.count {
            currentClippingIndex += 1
        } else {
            currentClippingIndex = 0 // Reset index if the array is exhausted
        }
        
        // In the background, append an additional random head clipping to the existing array
        DispatchQueue.global(qos: .background).async {
            self.appendRandomHeadClipping()
        }
    }

    // Append a new random head clipping to the currentHeadClippings array
    func appendRandomHeadClipping() {
        let allHeadClippings = headClippings
        guard !allHeadClippings.isEmpty else {
            print("No head clippings available to append")
            return
        }
        
        // Select a new random clipping that isn't already in the array
        if let newRandomClipping = allHeadClippings.filter({ !currentHeadClippings.contains($0) }).randomElement() {
            DispatchQueue.main.async {
                self.currentHeadClippings.append(newRandomClipping)
                print("Appended a new random head clipping: \(newRandomClipping.name)")
            }
        } else {
            print("No more unique clippings available to append")
        }
    }
    
    // function to update CoreData info
    func updateClippingTagsAndNames(oldName: String, newName: String, oldTags: [String], newTags: [String], context: NSManagedObjectContext) {
        // Update or delete the old head name if changed
        if oldName != newName {
            updateHeadNameCount(oldName, increment: -1, context: context)
            updateHeadNameCount(newName, increment: 1, context: context)
        }

        // Update tags
        let tagsToRemove = oldTags.filter { !newTags.contains($0) }
        let tagsToAdd = newTags.filter { !oldTags.contains($0) }

        // Process removals if any
        if !tagsToRemove.isEmpty {
            tagsToRemove.forEach { updateTagCount($0, increment: -1, context: context) }
        }

        // Process additions if any
        if !tagsToAdd.isEmpty {
            tagsToAdd.forEach { updateTagCount($0, increment: 1, context: context) }
        }
    }
    
    func updateHeadNameCount(_ name: String, increment: Int, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<HeadName> = HeadName.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        do {
            let results = try context.fetch(fetchRequest)
            if let headName = results.first {
                headName.count += Int64(increment)
                if headName.count <= 0 {
                    context.delete(headName)
                }
            } else if increment > 0 {
                let newHeadName = HeadName(context: context)
                newHeadName.name = name
                newHeadName.count = 1
            }
            try context.save()
        } catch {
            print("Error updating head name count: \(error)")
        }
    }
    
    func updateTagCount(_ tag: String, increment: Int, context: NSManagedObjectContext) {
        let fetchRequest = ClippingTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagString == %@", tag)

        do {
            let results = try context.fetch(fetchRequest)
            if let clippingTag = results.first {
                clippingTag.count += Int64(increment)
                if clippingTag.count <= 0 {
                    context.delete(clippingTag)
                }
                try context.save()
            } else if increment > 0 {
                let newTag = ClippingTag(context: context)
                newTag.tagString = tag
                newTag.count = 1
                try context.save()
            }
        } catch {
            print("Error updating tag count: \(error)")
        }
    }
    
    //MARK: - reporting functions
    
    var totalSources: Int {
        sources.count
    }
    
    var uniqueSourceNamesCount: Int {
        let uniqueNames = Set(sources.map { $0.title })
        return uniqueNames.count
    }
    
    var sourceYears: [Int] {
        sources.compactMap { Int($0.year) }
    }
    
    var minYear: Int? {
        sourceYears.min()
    }
    
    var maxYear: Int? {
        sourceYears.max()
    }
    
    var sourceYearCounts: [(year: Int, count: Int)] {
        let yearCounts = Dictionary(grouping: sources.compactMap { Int($0.year) }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        return yearCounts.map { (year: $0.key, count: $0.value) }
    }
    
    var sourceCounts: [(name: String, count: Int)] {
        let filteredSources = sources.filter { $0.title != "Unknown Magazine" }
        let counts = Dictionary(grouping: filteredSources) { $0.title }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        return counts.map { (name: $0.key, count: $0.value) }
    }
    
    // Function to get the count of sources added per year
    var sourcesPerYear: [(year: Int, count: Int)] {
        let calendar = Calendar.current
        let counts = Dictionary(grouping: sources.filter { $0.title != "Unknown Magazine" }) { source in
            calendar.component(.year, from: source.added)
        }
        .mapValues { $0.count }
        .sorted { $0.key < $1.key }

        return counts.map { (year: $0.key, count: $0.value) }
    }
    
    var averageClippingsPerSource: [(title: String, averageClippings: Double)] {
        let filteredSources = sources.filter { $0.title != "Unknown Magazine" }
        let groupedSources = Dictionary(grouping: filteredSources) { $0.title }
        return groupedSources.map { title, sources in
            let totalClippings = sources.reduce(0) { $0 + $1.clippings.count }
            let averageClippings = Double(totalClippings) / Double(sources.count)
            return (title, averageClippings)
        }
        .sorted { $0.averageClippings > $1.averageClippings }
    }
    var totalClippings: Int {
        sources.reduce(0) { $0 + $1.clippings.count }
    }
    
    var totalBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isBody == true }
            return result + qualifyingClippings.count
        }
    }
    
    var totalHeadNotBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isHead == true && $0.isBody == false }
            return result + qualifyingClippings.count
        }
    }
    
    var totalMaleHeadNotBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isHead == true && $0.isBody == false && $0.isMan == true }
            return result + qualifyingClippings.count
        }
    }
    
    var totalWomanHeadNotBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isHead == true && $0.isBody == false && $0.isWoman == true }
            return result + qualifyingClippings.count
        }
    }
    
    var totalTransHeadNotBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isHead == true && $0.isBody == false && $0.isTrans == true }
            return result + qualifyingClippings.count
        }
    }
    
    var totalAnimalHeadNotBodyClippings: Int {
        sources.reduce(0) { result, source in
            let qualifyingClippings = source.clippings.filter { $0.isHead == true && $0.isBody == false && $0.isAnimal == true }
            return result + qualifyingClippings.count
        }
    }
    
    var uniqueHeadNamesCount: Int {
        var uniqueNames = Set<String>()
        
        sources.forEach { source in
            let qualifyingClippings = source.clippings.filter { $0.isHead && !$0.isBody }
            let names = qualifyingClippings.map { $0.name }
            uniqueNames.formUnion(names)
        }
    
        return uniqueNames.count
    }
    
    var uniqueWomanHeadNamesCount: Int {
        var uniqueNames = Set<String>()
        
        sources.forEach { source in
            let qualifyingClippings = source.clippings.filter { $0.isHead && !$0.isBody && $0.isWoman }
            let names = qualifyingClippings.map { $0.name }
            uniqueNames.formUnion(names)
        }
    
        return uniqueNames.count
    }
    
    var uniqueManHeadNamesCount: Int {
        var uniqueNames = Set<String>()
        
        sources.forEach { source in
            let qualifyingClippings = source.clippings.filter { $0.isHead && !$0.isBody && $0.isMan }
            let names = qualifyingClippings.map { $0.name }
            uniqueNames.formUnion(names)
        }
    
        return uniqueNames.count
    }
    
    // Function to get the count of clippings added per year
    var clippingsPerYear: [(year: Int, count: Int)] {
        let calendar = Calendar.current
        let allClippings = sources.flatMap { $0.clippings }
        let counts = Dictionary(grouping: allClippings) { clipping in
            calendar.component(.year, from: clipping.added)
        }
        .mapValues { $0.count }
        .sorted { $0.key < $1.key }

        return counts.map { (year: $0.key, count: $0.value) }
    }
    
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var sourcesAddedCurrentYear: Int {
        sources.filter { Calendar.current.component(.year, from: $0.added) == currentYear }.count
    }
    
    var sourcesClippedCurrentYear: Int {
        sources.filter {
            Calendar.current.component(.year, from: $0.added) == currentYear &&
            !$0.clippings.isEmpty
        }.count
    }

    var clippingsAddedCurrentYear: Int {
        clippings.filter { Calendar.current.component(.year, from: $0.added) == currentYear }.count
    }
    
    var maleHeadsNames: [(name: String, count: Int)] {
        let allMaleHeadNames = clippings.filter { $0.isMan && $0.isHead && !$0.isBody }.map { $0.name }
        let nameCounts = Dictionary(grouping: allMaleHeadNames, by: { $0 }).mapValues { $0.count }
        return nameCounts.map { (key, value) in (name: key, count: value) }.sorted { $0.count > $1.count }
    }
    
    var femaleHeadsNames: [(name: String, count: Int)] {
        let allWomaleHeadNames = clippings.filter { $0.isWoman && $0.isHead && !$0.isBody }.map { $0.name }
        let nameCounts = Dictionary(grouping: allWomaleHeadNames, by: { $0 }).mapValues { $0.count }
        return nameCounts.map { (key, value) in (name: key, count: value) }.sorted { $0.count > $1.count }
    }

}

extension SourceModel {
    func reloadSources() {
        self.sources = [] // Completely clears sources prior to refreshing data -- necessary for logout
        DispatchQueue.main.async {
            self.getSources() // Refresh data from Firestore
        }
    }
}

extension SourceModel {
    func sources(for coverageFilter: SourceCoverageFilter) -> [Source] {
        switch coverageFilter {
        case .withClippings:
            return sources.filter { !$0.clippings.isEmpty }
        case .all:
            return sources
        case .unclippedOnly:
            return sources.filter { $0.clippings.isEmpty }
        }
    }
    
    var clippedSourcesCount: Int {
        sources(for: .withClippings).count
    }
    
    var unclippedSourcesCount: Int {
        sources(for: .unclippedOnly).count
    }
    
    func sourceYears(for coverageFilter: SourceCoverageFilter) -> [Int] {
        sources(for: coverageFilter).compactMap { Int($0.year) }
    }
    
    func minYear(for coverageFilter: SourceCoverageFilter) -> Int? {
        sourceYears(for: coverageFilter).min()
    }
    
    func maxYear(for coverageFilter: SourceCoverageFilter) -> Int? {
        sourceYears(for: coverageFilter).max()
    }
    
    func sourceYearCounts(for coverageFilter: SourceCoverageFilter) -> [(year: Int, count: Int)] {
        let yearCounts = Dictionary(grouping: sourceYears(for: coverageFilter)) { $0 }
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        return yearCounts.map { (year: $0.key, count: $0.value) }
    }
}

extension SourceModel {
    var sortedSources: [Source] {
        return self.sources.sorted {
            if $0.title != $1.title {
                return $0.title < $1.title
            } else {
                return $0.year < $1.year
            }
        }
    }
}

extension SourceModel {
    struct ClippingDataPoint: Identifiable {
        var id: UUID = UUID()
        var date: Date
        var count: Int
        
        var primitivePlottable: Double {
            date.timeIntervalSinceReferenceDate
        }
    }
    
    struct SourceDataPoint: Identifiable {
        var id: UUID = UUID()
        var date: Date
        var count: Int
    }
    
    func cumulativeClippingsData(showCurrentYearOnly: Bool) -> [ClippingDataPoint] {
        var dailyCounts: [Date: Int] = [:]
        
        for clipping in clippings {
            let date = Calendar.current.startOfDay(for: clipping.added)
            if showCurrentYearOnly {
                let currentYear = Calendar.current.component(.year, from: Date())
                let clippingYear = Calendar.current.component(.year, from: date)
                if clippingYear != currentYear {
                    continue
                }
            }
            dailyCounts[date, default: 0] += 1
        }
        
        let sortedDates = dailyCounts.keys.sorted()
        var cumulativeData: [ClippingDataPoint] = []
        var runningTotal = 0
        
        for date in sortedDates {
            runningTotal += dailyCounts[date]!
            cumulativeData.append(ClippingDataPoint(date: date, count: runningTotal))
        }
        
        return cumulativeData
    }
    
    func cumulativeSourcesData(showCurrentYearOnly: Bool) -> [SourceDataPoint] {
        var dailyCounts: [Date: Int] = [:]
        
        for source in sources {
            let date = Calendar.current.startOfDay(for: source.added)
            if showCurrentYearOnly {
                let currentYear = Calendar.current.component(.year, from: Date())
                let sourceYear = Calendar.current.component(.year, from: date)
                if sourceYear != currentYear {
                    continue
                }
            }
            dailyCounts[date, default: 0] += 1
        }
        
        let sortedDates = dailyCounts.keys.sorted()
        var cumulativeData: [SourceDataPoint] = []
        var runningTotal = 0
        
        for date in sortedDates {
            runningTotal += dailyCounts[date]!
            cumulativeData.append(SourceDataPoint(date: date, count: runningTotal))
        }
        
        return cumulativeData
    }
    
} 
