//
//  AppointmentsView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour gérer les rendez-vous
struct AppointmentsView: View {
    let child: Child
    
    var body: some View {
        List {
            Section {
                Text("Vue des rendez-vous pour \(child.firstName)")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Rendez-vous")
            } footer: {
                Text("Cette section permettra de gérer tous les rendez-vous de votre enfant.")
                    .font(.caption)
            }
        }
        .navigationTitle("Rendez-vous")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppointmentsView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
