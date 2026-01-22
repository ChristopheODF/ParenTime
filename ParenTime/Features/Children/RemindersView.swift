//
//  RemindersView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour gérer les rappels personnalisés
struct RemindersView: View {
    let child: Child
    
    var body: some View {
        List {
            Section {
                Text("Vue des rappels pour \(child.firstName)")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Rappels personnalisés")
            } footer: {
                Text("Cette section permettra de gérer tous les rappels personnalisés de votre enfant.")
                    .font(.caption)
            }
        }
        .navigationTitle("Rappels")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RemindersView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
