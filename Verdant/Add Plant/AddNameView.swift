//
//  AddPlantName.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData
import FoundationModels

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
    @State private var isGeneratingName = false
    @State private var showModelUnavailableAlert = false
    @State private var isDuplicateName = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismissSheet) private var dismissSheet
    
    @Query private var allPlants: [Plant]
    
    private let languageModel = SystemLanguageModel.default
    
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
                            .foregroundStyle(.orange)
                    }
                    
                    Button {
                        Task {
                            await generateRandomName()
                        }
                    } label: {
                        if isGeneratingName {
                            ProgressView()
                                .controlSize(.small)
                            Text("Generating...")
                        } else {
                            Label("Generate Random Name", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isGeneratingName || languageModel.availability != .available)
                }
                
                // Show helpful message if Apple Intelligence isn't available
                if languageModel.availability != .available {
                    Text(availabilityMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .alert("Apple Intelligence Unavailable", isPresented: $showModelUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(availabilityMessage)
        }
    }
    
    private var availabilityMessage: String {
        switch languageModel.availability {
        case .available:
            return ""
        case .unavailable(.deviceNotEligible):
            return "Your device doesn't support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings to use AI-generated names."
        case .unavailable(.modelNotReady):
            return "Apple Intelligence model is downloading or not ready."
        case .unavailable:
            return "Apple Intelligence is currently unavailable."
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
        // Species is already in the database, so we don't need to insert it
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
    
    private func generateRandomName() async {
        guard languageModel.availability == .available else {
            showModelUnavailableAlert = true
            return
        }
        
        isGeneratingName = true
        defer { isGeneratingName = false }
        
        let instructions = """
        You are a creative plant naming assistant. Generate a single, unique, and fun name for a house plant.
        The name should be creative, memorable, and appropriate for a beloved plant.
        You can draw inspiration from the plant's scientific name, characteristics, or appearance.
        Return only the plant name, nothing else. No quotes, no explanations.
        """
        
        let prompt = """
        Generate a creative name for a \(species.scientificName) plant.
        The name should be fun, memorable, and suitable for a house plant.
        Examples of good names: "Sir Leafington", "Verde the Magnificent", "Captain Chlorophyll"
        Return only the name.
        """
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            
            // Update the name on the main actor
            await MainActor.run {
                // Clean up the response (remove quotes if present)
                let generatedName = response.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                if !generatedName.isEmpty {
                    name = generatedName
                }
            }
        } catch {
            print("Failed to generate name: \(error)")
            // Optionally show an error alert
        }
    }
}

#Preview {
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
