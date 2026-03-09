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
            scientificName: "Epipremnum aureum",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 1000...3000,
            healthyTemperatureRange: 18...29,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Sansevieria trifasciata",
            healthySoilMoistureRange: 20...40,
            healthyLightRange: 500...5000,
            healthyTemperatureRange: 15...29,
            healthyHumidityRange: 30...50
        ),
        Species(
            scientificName: "Monstera deliciosa",
            healthySoilMoistureRange: 50...70,
            healthyLightRange: 2000...4000,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 60...80
        ),
        Species(
            scientificName: "Ficus lyrata",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 3500...5000,
            healthyTemperatureRange: 18...24,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Spathiphyllum wallisii",
            healthySoilMoistureRange: 60...80,
            healthyLightRange: 1000...2500,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 50...70
        ),
        Species(
            scientificName: "Chlorophytum comosum",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 1500...4000,
            healthyTemperatureRange: 15...24,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Aloe vera",
            healthySoilMoistureRange: 20...40,
            healthyLightRange: 4000...6000,
            healthyTemperatureRange: 13...27,
            healthyHumidityRange: 30...50
        ),
        Species(
            scientificName: "Ficus elastica",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 2500...4500,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Zamioculcas zamiifolia",
            healthySoilMoistureRange: 20...40,
            healthyLightRange: 500...3500,
            healthyTemperatureRange: 15...27,
            healthyHumidityRange: 30...50
        ),
        Species(
            scientificName: "Philodendron hederaceum",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 1500...3500,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 50...70
        ),
        Species(
            scientificName: "Nephrolepis exaltata",
            healthySoilMoistureRange: 70...90,
            healthyLightRange: 1500...3500,
            healthyTemperatureRange: 16...24,
            healthyHumidityRange: 70...90
        ),
        Species(
            scientificName: "Hedera helix",
            healthySoilMoistureRange: 50...70,
            healthyLightRange: 1500...3500,
            healthyTemperatureRange: 10...21,
            healthyHumidityRange: 50...70
        ),
        Species(
            scientificName: "Calathea ornata",
            healthySoilMoistureRange: 60...80,
            healthyLightRange: 1000...2500,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 60...80
        ),
        Species(
            scientificName: "Dracaena marginata",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 1500...3500,
            healthyTemperatureRange: 18...24,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Echeveria elegans",
            healthySoilMoistureRange: 10...30,
            healthyLightRange: 5000...8000,
            healthyTemperatureRange: 15...27,
            healthyHumidityRange: 20...40
        ),
        Species(
            scientificName: "Ficus pumila",
            healthySoilMoistureRange: 50...70,
            healthyLightRange: 2000...4000,
            healthyTemperatureRange: 16...24,
            healthyHumidityRange: 50...70
        ),
        Species(
            scientificName: "Chamaedorea elegans",
            healthySoilMoistureRange: 50...70,
            healthyLightRange: 1000...3000,
            healthyTemperatureRange: 18...27,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Peperomia obtusifolia",
            healthySoilMoistureRange: 40...60,
            healthyLightRange: 1500...3500,
            healthyTemperatureRange: 18...24,
            healthyHumidityRange: 40...60
        ),
        Species(
            scientificName: "Fittonia albivenis",
            healthySoilMoistureRange: 60...80,
            healthyLightRange: 1000...2500,
            healthyTemperatureRange: 18...24,
            healthyHumidityRange: 60...80
        ),
        Species(
            scientificName: "Crassula ovata",
            healthySoilMoistureRange: 20...40,
            healthyLightRange: 4000...6000,
            healthyTemperatureRange: 15...24,
            healthyHumidityRange: 30...50
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
        case "Fittonia albivenis": return "Nerve Plant"
        case "Crassula ovata": return "Jade Plant"
        default: return scientificName
        }
    }
}

struct PickSpeciesView : View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    var filteredSpecies: [Species] {
        if searchText.isEmpty {
            return Species.library
        } else {
            return Species.library.filter { species in
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
}

