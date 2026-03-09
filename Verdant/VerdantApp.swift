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
        // Fetch all existing species
        let descriptor = FetchDescriptor<Species>()
        let existingSpecies = (try? context.fetch(descriptor)) ?? []
        
        // Create a dictionary for quick lookup by scientific name
        var existingSpeciesDict: [String: Species] = [:]
        for species in existingSpecies {
            existingSpeciesDict[species.scientificName] = species
        }
        
        var updatedCount = 0
        var insertedCount = 0
        
        // Insert or update species from the library
        for librarySpecies in Species.library {
            if let existingSpecies = existingSpeciesDict[librarySpecies.scientificName] {
                // Update existing species without breaking relationships
                existingSpecies.healthySoilMoistureRange = librarySpecies.healthySoilMoistureRange
                existingSpecies.healthyLightRange = librarySpecies.healthyLightRange
                existingSpecies.healthyTemperatureRange = librarySpecies.healthyTemperatureRange
                existingSpecies.healthyHumidityRange = librarySpecies.healthyHumidityRange
                updatedCount += 1
            } else {
                // Insert new species
                let newSpecies = Species(
                    scientificName: librarySpecies.scientificName,
                    healthySoilMoistureRange: librarySpecies.healthySoilMoistureRange,
                    healthyLightRange: librarySpecies.healthyLightRange,
                    healthyTemperatureRange: librarySpecies.healthyTemperatureRange,
                    healthyHumidityRange: librarySpecies.healthyHumidityRange
                )
                context.insert(newSpecies)
                insertedCount += 1
            }
        }
        
        // Save the context
        do {
            try context.save()
            print("Species library updated: \(insertedCount) inserted, \(updatedCount) updated")
        } catch {
            print("Failed to update species library: \(error)")
        }
    }
}
