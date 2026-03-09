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

struct AddPlantName : View {
    var species: Species
    @State private var name: String = ""
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismissSheet) private var dismissSheet
    
    var body: some View {
        VStack {
            TextField("Your plant's name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            Button {
                name = generateRandomName()
            } label: {
                Label("Generate Random Name", systemImage: "sparkles")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    addPlant()
                } label: {
                    Label("Add Plant", systemImage: "checkmark")
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private func addPlant() {
        let newPlant = Plant(name: name, species: species)
        modelContext.insert(newPlant)
        dismissSheet?()
    }
    
    private func generateRandomName() -> String {
        let prefixes: [String] = ["Sir", "Lady", "Prince", "Princess", "Duke", "Duchess", "Captain", "Professor", "Dr.", "Mr.", "Ms."]
        let plantNames: [String] = [
            "Leafy", "Verde", "Sprout", "Bloom", "Fern", "Ivy", "Sage", "Basil", 
            "Clover", "Jade", "Willow", "Forest", "Meadow", "Petal", "Stem"
        ]
        let suffixes: [String] = ["the Green", "the Magnificent", "the Great", "the Wise", "the Brave", "Jr.", "III"]
        
        // Species-specific themes - broken up to help the compiler
        var speciesThemes: [String: [String]] = [:]
        speciesThemes["Monstera deliciosa"] = ["Swiss", "Monterey", "Holey", "Fenestra"]
        speciesThemes["Ficus lyrata"] = ["Fiddle", "Lyra", "Fig", "Figaro"]
        speciesThemes["Epipremnum aureum"] = ["Golden", "Pothos", "Devil", "Aureus"]
        speciesThemes["Sansevieria trifasciata"] = ["Snake", "Viper", "Striker", "Sansa"]
        speciesThemes["Spathiphyllum wallisii"] = ["Peace", "Lily", "Serenity", "Tranquil"]
        speciesThemes["Aloe vera"] = ["Aloe", "Spike", "Vera", "Succulent"]
        speciesThemes["Ficus pumila"] = ["Creeper", "Ivy", "Climber", "Fig"]
        speciesThemes["Chamaedorea elegans"] = ["Palmy", "Elegance", "Neanthe", "Bella"]
        speciesThemes["Peperomia obtusifolia"] = ["Pepper", "Pepe", "Baby", "Rubber"]
        speciesThemes["Fittonia albivenis"] = ["Mosaic", "Nerve", "Silver", "Fitz"]
        speciesThemes["Crassula ovata"] = ["Jade", "Lucky", "Money", "Tree"]
        speciesThemes["Zamioculcas zamiifolia"] = ["Zamicro", "Zee", "Zamiifolia", "Immortal"]
        
        var nameComponents: [String] = []
        
        // Sometimes add a prefix (40% chance)
        let shouldAddPrefix = Bool.random()
        let prefixChance = Double.random(in: 0...1)
        if shouldAddPrefix && prefixChance < 0.4 {
            if let prefix = prefixes.randomElement() {
                nameComponents.append(prefix)
            }
        }
        
        // Add species-specific or generic plant name
        if let themeNames = speciesThemes[species.scientificName] {
            let useTheme = Bool.random()
            if useTheme {
                if let themeName = themeNames.randomElement() {
                    nameComponents.append(themeName)
                }
            } else {
                if let plantName = plantNames.randomElement() {
                    nameComponents.append(plantName)
                }
            }
        } else {
            if let plantName = plantNames.randomElement() {
                nameComponents.append(plantName)
            }
        }
        
        // Sometimes add a suffix (30% chance)
        let shouldAddSuffix = Bool.random()
        let suffixChance = Double.random(in: 0...1)
        if shouldAddSuffix && suffixChance < 0.3 {
            if let suffix = suffixes.randomElement() {
                nameComponents.append(suffix)
            }
        }
        
        return nameComponents.joined(separator: " ")
    }
}

#Preview {
    let species = Species(
        scientificName: "Peperomia obtusifolia",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 1000...3000,
        healthyTemperatureRange: 18...24,
        healthyHumidityRange: 40...60
    )
    
    NavigationStack {
        AddPlantName(species: species)
    }
}
