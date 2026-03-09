//
//  AddPlantName.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData

// Custom environment key to dismiss the entire sheet from nested views
struct DismissSheetKey: EnvironmentKey {
    static let defaultValue: DismissAction? = nil
}

extension EnvironmentValues {
    var dismissSheet: DismissAction? {
        get { self[DismissSheetKey.self] }
        set { self[DismissSheetKey.self] = newValue }
    }
}

struct AddNameView : View {
    var species: Species
    @State private var name: String = ""
    @State private var isDuplicateName = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismissSheet) private var dismissSheet
    
    @Query private var allPlants: [Plant]
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name your plant")
                        .font(Font.largeTitle.bold())
                    Text("Your plant's name will be used to identify it. You can always change it later.")
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Your plant's name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    // Show warning if name is duplicate
                    if isDuplicateName {
                        Label("You already have a plant with this name", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .labelIconToTitleSpacing(4)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Button {
                addPlant()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear {
            if name.isEmpty {
                name = generateDefaultName()
            }
        }
        .onChange(of: name) { oldValue, newValue in
            checkForDuplicateName(newValue)
        }
    }
    
    private func generateDefaultName() -> String {
        let baseName = species.commonName
        let existingNames = allPlants.map { $0.name }
        
        // Check if the base name is available
        if !existingNames.contains(baseName) {
            return baseName
        }
        
        // Find the next available number
        var number = 2
        while existingNames.contains("\(baseName) #\(number)") {
            number += 1
        }
        
        return "\(baseName) #\(number)"
    }
    
    private func checkForDuplicateName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        isDuplicateName = allPlants.contains { $0.name.lowercased() == trimmedName.lowercased() }
    }
    
    private func addPlant() {
        let newPlant = Plant(name: name, species: species)
        modelContext.insert(newPlant)
        
        // Save the context to persist the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save plant: \(error)")
        }
        
        dismissSheet?()
    }
}

#Preview("Default") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Species.self, configurations: config)
    
    let species = Species(
        scientificName: "Peperomia obtusifolia",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 1000...3000,
        healthyTemperatureRange: 18...24,
        healthyHumidityRange: 40...60
    )
    
    container.mainContext.insert(species)
    
    // Add some existing plants to test the numbering
    let plant1 = Plant(name: "Peperomia", species: species)
    let plant2 = Plant(name: "Peperomia #2", species: species)
    container.mainContext.insert(plant1)
    container.mainContext.insert(plant2)
    
    return NavigationStack {
        AddNameView(species: species)
    }
    .modelContainer(container)
}
