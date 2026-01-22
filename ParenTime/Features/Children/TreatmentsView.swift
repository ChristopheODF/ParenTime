//
//  TreatmentsView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour gérer les traitements
struct TreatmentsView: View {
    let child: Child
    
    var body: some View {
        List {
            Section {
                Text("Vue des traitements pour \(child.firstName)")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Traitements")
            } footer: {
                Text("Cette section permettra de gérer tous les traitements de votre enfant.")
                    .font(.caption)
            }
        }
        .navigationTitle("Traitements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TreatmentsView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
