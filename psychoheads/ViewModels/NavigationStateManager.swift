//
//  NavigationStateManager.swift
//  psychoheads
//
//  Created by Ryan Pavlovicz on 4/23/23.
//

import SwiftUI
import Foundation
import Combine

enum SelectionState: Hashable, Codable {

//    case psychoView
    
    // Account settings
    case accountSettings
    case newUser
    case existingUser
    
    // Library navigation states
    case library
    case imageCapture
    case sourceView(Source)
    case clippingView(Clipping)
    case clippingsSwipeView([Clipping], currentIndex: Int)
    case editClippingView(Clipping)
    case editClippingSourceView(Clipping)
    case edit(Source)
    case searchClippings([Clipping]?)
    case collageView
    case reportView
    case reportSourceDetailView
    case reportClippingDetailView
    case progressReportView
    case tempClippingView
    case imageDiagnostics

}

class NavigationStateManager: ObservableObject {
    
    @Published var selectionPath = [SelectionState]()
    
//    func goToLibrary() {
//        selectionPath = [SelectionState.library]
//    }
    
//    func goToPsycho() {
//        selectionPath = [SelectionState.psychoView]
//    }
    
    var data: Data? {
        get {
            try? JSONEncoder().encode(selectionPath)
        }
        set {
            guard let data = newValue,
                  let path = try? JSONDecoder().decode([SelectionState].self, from: data) else {
                return
            }
            self.selectionPath = path
        }
    }
    
    func popBack() {
        print("length of selectionPath before popBack = \(selectionPath.count)")
        selectionPath.removeLast()
        print("length of selectionPath after popBack = \(selectionPath.count)")
    }
    
}
