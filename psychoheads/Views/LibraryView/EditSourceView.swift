//
//  EditSourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 6/26/25.
//


//
//  EditSourceView.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 4/3/23.
//

import SwiftUI

struct OriginalSourceData {
    let title: String
    let type: String
    let year: String
    let month: String
    let day: String
    let issue: String
    let ncopies: Int
}

struct EditSourceView: View {
    
    @EnvironmentObject var sourceModel: SourceModel
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    
    @ObservedObject var source: Source
    
    @State private var title: String
    @State private var type: String
    @State private var year: String
    @State private var month: String
    @State private var day: String
    @State private var issue: String
    @State private var ncopies: Int
    @State private var originalData: OriginalSourceData

    @State private var isSaving: Bool = false
    @State private var showSaveError: Bool = false
    @State private var saveErrorMessage: String = ""
    
    private let sourceOptions = ["", "Magazine", "Book", "Other"]
    private let years = [""] + (1970...Calendar.current.component(.year, from: Date())).reversed().map(String.init)
    private let dayOptions = [""] + (1...31).map(String.init)
    
    private var hasChanges: Bool {
        normalized(title) != normalized(originalData.title) ||
        normalized(type) != normalized(originalData.type) ||
        normalized(year) != normalized(originalData.year) ||
        normalized(month) != normalized(originalData.month) ||
        normalized(day) != normalized(originalData.day) ||
        normalized(issue) != normalized(originalData.issue) ||
        ncopies != originalData.ncopies
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !type.isEmpty &&
        !year.isEmpty
    }
    
    private func normalized(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    init(source: Source) {
        self.source = source
        let initial = OriginalSourceData(
            title: source.title,
            type: source.type,
            year: source.year,
            month: source.month ?? "",
            day: source.day ?? "",
            issue: source.issue ?? "",
            ncopies: source.ncopies
        )
        _originalData = State(initialValue: initial)
        _title = State(initialValue: source.title)
        _type = State(initialValue: source.type)
        _year = State(initialValue: source.year)
        _month = State(initialValue: source.month ?? "")
        _day = State(initialValue: source.day ?? "")
        _issue = State(initialValue: source.issue ?? "")
        _ncopies = State(initialValue: source.ncopies)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Source Details")) {
                    TextField("Title", text: $title)
                        .onSubmit {
                            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    
                    Picker("Source Type", selection: $type) {
                        ForEach(sourceOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { year in
                            Text(year)
                        }
                    }
                    
                    TextField("Month/Season", text: $month)
                        .onSubmit {
                            month = month.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    
                    Picker("Date", selection: $day) {
                        ForEach(dayOptions, id: \.self) { value in
                            Text(value)
                        }
                    }
                    
                    TextField("Issue", text: $issue)
                        .onSubmit {
                            issue = issue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    
                    Stepper(value: $ncopies, in: 1...20) {
                        HStack {
                            Text("Number of copies")
                            Spacer()
                            Text("\(ncopies)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            VStack(spacing: 10) {
                Button {
                    guard !isSaving else { return }
                    isSaving = true
                    
                    let updatedSource = Source(copyFrom: source)
                    updatedSource.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedSource.type = type
                    updatedSource.year = year
                    updatedSource.month = month.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedSource.day = day.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedSource.issue = issue.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedSource.ncopies = ncopies
                    
                    sourceModel.updateSource(updatedSource) { success in
                        DispatchQueue.main.async {
                            isSaving = false
                            if success {
                                source.update(from: updatedSource)
                                navigationStateManager.popBack()
                            } else {
                                saveErrorMessage = "Could not update source. Please try again."
                                showSaveError = true
                            }
                        }
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Changes")
                    }
                }
                .disabled(!hasChanges || !isFormValid || isSaving)
                .buttonStyle(ButtonStyle1(inputColor: (!hasChanges || !isFormValid || isSaving) ? .lightGray : .blue))
                .padding(.horizontal, 40)
                
                Button("Cancel") {
                    navigationStateManager.popBack()
                }
                .buttonStyle(ButtonStyle1(inputColor: .gray))
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            }
            .padding(.top, 8)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Edit Source")
        .alert("Update Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
}

struct EditSourceView_Previews: PreviewProvider {
    static var previews: some View {
        let source = Source(title: "Preview Magazine", year: "1994", month: "June")
        source.id = "preview-source-1"
        source.ncopies = 3
        source.type = "Magazine"
        return NavigationStack {
            EditSourceView(source: source)
                .environmentObject(SourceModel())
                .environmentObject(NavigationStateManager())
        }
        .previewDisplayName("Edit source")
    }
}
