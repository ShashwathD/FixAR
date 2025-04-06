//
//  _ProjectApp.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/5/25.
//

import SwiftUI

@main
struct _ProjectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
