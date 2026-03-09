//
//  VerdantApp.swift
//  Verdant
//
//  Created by Ryan Tessier on 7/3/2026.
//

import SwiftUI
import SwiftData

@main
struct VerdantApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Create the model container
            modelContainer = try ModelContainer(for: Plant.self, Species.self)
            
            // Seed the database with species on first launch
            seedSpeciesIfNeeded(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
    
    private func seedSpeciesIfNeeded(context: ModelContext) {
        // Check if species already exist
        let descriptor = FetchDescriptor<Species>()
        let existingSpecies = (try? context.fetch(descriptor)) ?? []
        
        // Only seed if the database is empty
        guard existingSpecies.isEmpty else { return }
        
        // Insert all species from the library
        for species in Species.library {
            context.insert(species)
        }
        
        // Save the context
        do {
            try context.save()
            print("Successfully seeded \(Species.library.count) species")
        } catch {
            print("Failed to seed species: \(error)")
        }
    }
}
