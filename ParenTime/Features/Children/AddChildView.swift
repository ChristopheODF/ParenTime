//
//  AddChildView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour ajouter un nouvel enfant
struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    
    let onAdd: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Prénom", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Nom", text: $lastName)
                        .textContentType(.familyName)
                }
                
                Section {
                    Button("Ajouter") {
                        onAdd(firstName, lastName)
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Nouvel Enfant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddChildView { firstName, lastName in
        print("Add child: \(firstName) \(lastName)")
    }
}
