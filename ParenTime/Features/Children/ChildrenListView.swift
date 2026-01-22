//
//  ChildrenListView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue principale pour afficher la liste des enfants
struct ChildrenListView: View {
    @StateObject private var viewModel: ChildrenViewModel
    
    init(childrenStore: ChildrenStore) {
        _viewModel = StateObject(wrappedValue: ChildrenViewModel(childrenStore: childrenStore))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if viewModel.children.isEmpty {
                    emptyStateView
                } else {
                    childrenList
                }
            }
            .navigationTitle("Mes Enfants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddChildView { firstName, lastName, birthDate in
                    Task {
                        await viewModel.addChild(firstName: firstName, lastName: lastName, birthDate: birthDate)
                    }
                }
            }
            .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await viewModel.loadChildren()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Aucun enfant")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Appuyez sur + pour ajouter votre premier enfant")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var childrenList: some View {
        List {
            ForEach(viewModel.children) { child in
                NavigationLink(destination: ChildDetailView(child: child)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.fullName)
                            .font(.headline)
                        if let age = child.age() {
                            Text("\(age) ans")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.deleteChild(at: offsets)
                }
            }
        }
    }
}

#Preview {
    ChildrenListView(childrenStore: InMemoryChildrenStore(initialChildren: [
        Child(firstName: "Alice", lastName: "Dupont", birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!),
        Child(firstName: "Bob", lastName: "Martin", birthDate: Calendar.current.date(byAdding: .year, value: -8, to: Date())!)
    ]))
}
