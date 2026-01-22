//
//  ChildrenViewModel.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import SwiftUI

/// ViewModel pour la liste des enfants
@MainActor
final class ChildrenViewModel: ObservableObject {
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddSheet = false
    
    private let childrenStore: ChildrenStore
    
    init(childrenStore: ChildrenStore) {
        self.childrenStore = childrenStore
    }
    
    func loadChildren() async {
        isLoading = true
        errorMessage = nil
        
        do {
            children = try await childrenStore.fetchChildren()
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addChild(firstName: String, lastName: String) async {
        let newChild = Child(firstName: firstName, lastName: lastName)
        
        do {
            try await childrenStore.addChild(newChild)
            await loadChildren()
        } catch {
            errorMessage = "Erreur lors de l'ajout: \(error.localizedDescription)"
        }
    }
    
    func deleteChild(at offsets: IndexSet) async {
        for index in offsets {
            let child = children[index]
            do {
                try await childrenStore.deleteChild(id: child.id)
            } catch {
                errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            }
        }
        await loadChildren()
    }
}
