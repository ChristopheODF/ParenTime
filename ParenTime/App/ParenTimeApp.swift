//
//  ParenTimeApp.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

@main
struct ParenTimeApp: App {
    @StateObject private var container = AppContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ChildrenListView(childrenStore: container.childrenStore)
                .environment(\.appContainer, container)
        }
    }
}
