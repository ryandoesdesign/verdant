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
        // Fetch existing species
        let descriptor = FetchDescriptor<Species>()
        let existingSpecies = (try? context.fetch(descriptor)) ?? []
        
        // Create a dictionary of existing species by scientific name for quick lookup
        let existingSpeciesDict = Dictionary(uniqueKeysWithValues: existingSpecies.map { ($0.scientificName, $0) })
        
        var addedCount = 0
        var updatedCount = 0
        
        // Process each species in the library
        for librarySpecies in Species.library {
            if let existingSpecies = existingSpeciesDict[librarySpecies.scientificName] {
                // Species exists - check if it needs updating
                var needsUpdate = false
                
                if existingSpecies.healthySoilMoistureRange != librarySpecies.healthySoilMoistureRange {
                    existingSpecies.healthySoilMoistureRange = librarySpecies.healthySoilMoistureRange
                    needsUpdate = true
                }
                
                if existingSpecies.healthyLightRange != librarySpecies.healthyLightRange {
                    existingSpecies.healthyLightRange = librarySpecies.healthyLightRange
                    needsUpdate = true
                }
                
                if existingSpecies.healthyTemperatureRange != librarySpecies.healthyTemperatureRange {
                    existingSpecies.healthyTemperatureRange = librarySpecies.healthyTemperatureRange
                    needsUpdate = true
                }
                
                if existingSpecies.healthyHumidityRange != librarySpecies.healthyHumidityRange {
                    existingSpecies.healthyHumidityRange = librarySpecies.healthyHumidityRange
                    needsUpdate = true
                }
                
                if needsUpdate {
                    updatedCount += 1
                }
            } else {
                // Species doesn't exist - add it
                context.insert(librarySpecies)
                addedCount += 1
            }
        }
        
        // Save the context if there were any changes
        if addedCount > 0 || updatedCount > 0 {
            do {
                try context.save()
                print("Species sync complete: \(addedCount) added, \(updatedCount) updated (total: \(Species.library.count))")
            } catch {
                print("Failed to sync species: \(error)")
            }
        } else {
            print("All \(Species.library.count) species are up to date")
        }
    }
}
