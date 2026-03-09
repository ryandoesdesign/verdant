//
//  AddPlantView.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData

extension Species {
    static let library: [Species] = [
        Species(
            scientificName: "Zamioculcas zamiifolia",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 600...20000,
            healthyTemperatureRange: 10...32,
            healthyHumidityRange: 30...80
        ),
        Species(
            scientificName: "Ficus pumila",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 1500...6000,
            healthyTemperatureRange: 10...32,
            healthyHumidityRange: 30...85
        ),
        Species(
            scientificName: "Chamaedorea elegans",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 800...22000,
            healthyTemperatureRange: 10...32,
            healthyHumidityRange: 30...85
        ),
        Species(
            scientificName: "Peperomia polybotrya",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 1500...6000,
            healthyTemperatureRange: 10...32,
            healthyHumidityRange: 30...85
        ),
        Species(
            scientificName: "Fittonia albivenis",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 500...26000,
            healthyTemperatureRange: 10...35,
            healthyHumidityRange: 30...85
        ),
    ]
    
    var commonName: String {
        switch scientificName {
        case "Epipremnum aureum": return "Pothos"
        case "Sansevieria trifasciata": return "Snake Plant"
        case "Monstera deliciosa": return "Monstera"
        case "Ficus lyrata": return "Fiddle Leaf Fig"
        case "Spathiphyllum wallisii": return "Peace Lily"
        case "Chlorophytum comosum": return "Spider Plant"
        case "Aloe vera": return "Aloe Vera"
        case "Ficus elastica": return "Rubber Plant"
        case "Zamioculcas zamiifolia": return "ZZ Plant"
        case "Philodendron hederaceum": return "Philodendron"
        case "Nephrolepis exaltata": return "Boston Fern"
        case "Hedera helix": return "English Ivy"
        case "Calathea ornata": return "Calathea"
        case "Dracaena marginata": return "Dracaena"
        case "Echeveria elegans": return "Succulent"
        case "Ficus pumila": return "Creeping Fig"
        case "Chamaedorea elegans": return "Parlor Palm"
        case "Peperomia obtusifolia": return "Peperomia"
        case "Peperomia polybotrya": return "Raindrop Peperomia"
        case "Fittonia albivenis": return "Nerve Plant"
        case "Crassula ovata": return "Jade Plant"
        default: return scientificName
        }
    }
}

struct PickSpeciesView : View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Species.scientificName) private var allSpecies: [Species]
    
    @State private var searchText = ""
    
    var filteredSpecies: [Species] {
        if searchText.isEmpty {
            return allSpecies
        } else {
            return allSpecies.filter { species in
                species.commonName.localizedCaseInsensitiveContains(searchText) ||
                species.scientificName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add a plant")
                        .font(Font.largeTitle.bold())
                    Text("Find your plant's species.")
                }
                if (filteredSpecies.isEmpty && !searchText.isEmpty) {
                    ContentUnavailableView("No plants found.", systemImage: "magnifyingglass")
                } else {
                    ForEach(filteredSpecies, id: \.scientificName) { species in
                        NavigationLink {
                            AddNameView(species: species)
                                .environment(\.dismissSheet, dismiss)
                        } label: {
                            HStack(spacing: 12) {
                                PlantImage(data: nil)
                                    .frame(width: 48, height: 48)
                                    .aspectRatio(contentMode: .fill)
                                
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(species.commonName)
                                        .font(.headline)
                                    Text(species.scientificName)
                                        .font(.caption)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                            }
                            .tag(species)
                        }
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search plants")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
        }
        
    }
}
#Preview {
    NavigationStack {
        PickSpeciesView()
    }
    .modelContainer(for: Species.self) { result in
        guard case .success(let container) = result else {
            fatalError("Failed to create model container")
        }
        
        // Insert all species from the library
        for species in Species.library {
            container.mainContext.insert(species)
        }
    }
}

