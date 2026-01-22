//
//  VaccinesView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour gérer les vaccins
struct VaccinesView: View {
    let child: Child
    
    var body: some View {
        List {
            Section {
                Text("Vue des vaccins pour \(child.firstName)")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Vaccins")
            } footer: {
                Text("Cette section permettra de gérer tous les vaccins de votre enfant.")
                    .font(.caption)
            }
        }
        .navigationTitle("Vaccins")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        VaccinesView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
