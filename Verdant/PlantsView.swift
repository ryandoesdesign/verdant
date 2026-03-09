//
//  PlantsView.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData

struct PlantGridCell: View {
    let plant: Plant
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlantImage(data: plant.image)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name)
                    .font(.headline)
                
                Text(plant.species.scientificName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Plant", systemImage: "trash")
            }
        }
    }
}

struct PlantsView : View {
    @Query var plants: [Plant]
    @State private var showingAddPlant = false
    @State private var plantToDelete: Plant?
    @Environment(\.modelContext) private var modelContext
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible())
    ]
    
    var body: some View {
        Group {
            if (plants.isEmpty) {
                ContentUnavailableView(
                    "No Plants",
                    systemImage: "leaf",
                    description: Text("Add your first plant to get started tracking its health and care.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(plants) { plant in
                            NavigationLink {
                                PlantDetailView(plant: plant)
                            } label: {
                                PlantGridCell(plant: plant, onDelete: { 
                                    plantToDelete = plant
                                })
                                .confirmationDialog(
                                    "Delete Plant",
                                    isPresented: Binding(
                                        get: { plantToDelete != nil },
                                        set: { if !$0 { plantToDelete = nil } }
                                    ),
                                    presenting: plantToDelete
                                ) { plant in
                                    Button("Delete Plant", role: .destructive) {
                                        deletePlant(plant)
                                    }
                                    Button("Cancel", role: .cancel) {
                                        plantToDelete = nil
                                    }
                                } message: { plant in
                                    Text("Are you sure you want to delete \(plant.name)?")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Text("Plants"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPlant = true
                } label: {
                    Label("Add Plant", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlant) {
            NavigationStack {
                PickSpeciesView()
            }
        }
    }
    
    private func deletePlant(_ plant: Plant) {
        modelContext.delete(plant)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete plant: \(error)")
        }
    }
}

#Preview("With Plants") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Species.self, configurations: config)
    
    let monsteraSpecies = Species(
        scientificName: "Monstera deliciosa",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let ficusSpecies = Species(
        scientificName: "Ficus lyrata",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let pothosSpecies = Species(
        scientificName: "Epipremnum aureum",
        healthySoilMoistureRange: 30...50,
        healthyLightRange: 5000...15000,
        healthyTemperatureRange: 17...27,
        healthyHumidityRange: 50...70
    )
    
    let peperomiaSpecies = Species(
        scientificName: "Peperomia polybotrya",
        healthySoilMoistureRange: 30...50,
        healthyLightRange: 8000...16000,
        healthyTemperatureRange: 18...24,
        healthyHumidityRange: 40...60
    )
    
    let plant1 = Plant(name: "Swiss Cheese Plant", species: monsteraSpecies, image: UIImage(named: "Monstera")?.jpegData(compressionQuality: 0.8))
    
    let plant2 = Plant(name: "Fiddle Leaf Fig", species: ficusSpecies, image: UIImage(named: "CreepingFig")?.jpegData(compressionQuality: 0.8))
    
    let plant3 = Plant(name: "Golden Pothos", species: pothosSpecies, image: UIImage(named: "Pothos")?.jpegData(compressionQuality: 0.8))
    
    let plant4 = Plant(name: "Raindrop Peperomia", species: peperomiaSpecies, image: UIImage(named: "Peperomia")?.jpegData(compressionQuality: 0.8))
    
    container.mainContext.insert(plant1)
    container.mainContext.insert(plant2)
    container.mainContext.insert(plant3)
    container.mainContext.insert(plant4)
    
    return NavigationStack {
        PlantsView()
    }
    .modelContainer(container)
}
#Preview("No Plants") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Species.self, configurations: config)
    
    return NavigationStack {
        PlantsView()
    }
    .modelContainer(container)
}

