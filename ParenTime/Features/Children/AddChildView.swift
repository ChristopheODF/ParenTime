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
    @State private var birthDate: Date = {
        // Default to 10 years ago for better UX
        // Use a fixed fallback date if calculation fails
        let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: Date())
        return tenYearsAgo ?? Date(timeIntervalSince1970: 315532800) // Jan 1, 1980 as fallback
    }()
    
    let onAdd: (String, String, Date) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Prénom", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Nom", text: $lastName)
                        .textContentType(.familyName)
                }
                
                Section("Date de naissance") {
                    DatePicker(
                        "Date de naissance",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                
                Section {
                    Button("Ajouter") {
                        onAdd(firstName, lastName, birthDate)
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
    AddChildView { firstName, lastName, birthDate in
        print("Add child: \(firstName) \(lastName), born \(birthDate)")
    }
}
