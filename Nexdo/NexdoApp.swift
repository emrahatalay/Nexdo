//
//  NexdoApp.swift
//  Nexdo
//
//  Created by Emrah Atalay on 2.10.2026.
//

import SwiftUI
import CoreData

@main
struct NexdoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
