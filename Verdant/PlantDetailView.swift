//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Ryan Tessier on 7/3/2026.
//

import SwiftUI
import Charts

// MARK: - Plant Detail View

struct PlantDetailView: View {
    let plant: Plant
    
    @State private var isPairingSensorPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PlantImage(data: plant.image)
                    .frame(height: 187)
                
                if let sensorId = plant.sensorIdentifier {
                    Text("Paired: \(sensorId)")
                        .font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                        Text("Soil Moisture")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    
                    SoilMoistureChart(
                        healthyRange: plant.species.healthySoilMoistureRange,
                        currentCycleMeasurements: plant.soilMoistureMeasurements
                    )
                    .frame(minHeight: 200)
                    
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                        Text("Light")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    
                    LightChart(
                        healthyRange: plant.species.healthyLightRange,
                        measurements: plant.lightMeasurements
                    )
                    .frame(minHeight: 200)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(plant.name)
        .navigationSubtitle(plant.species.scientificName)
        .sheet(isPresented: $isPairingSensorPresented) {
            NavigationStack {
                PairSensorView(plant: plant)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPairingSensorPresented = true
                } label: {
                    Label("Pair with Sensor", systemImage: "sensor")
                }
            }
        }
        
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlantDetailView(plant:
            Plant(
                name: "Pepe",
                species: Species(
                    scientificName: "Peperomia polybotrya",
                    healthySoilMoistureRange: 15...60,
                    healthyLightRange: 1500...6000,
                    healthyTemperatureRange: 18...24,
                    healthyHumidityRange: 40...60
                ),
                image: UIImage(named: "Peperomia")?.jpegData(compressionQuality: 0.8)
            )
        )
    }
}

