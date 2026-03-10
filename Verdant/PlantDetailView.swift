//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Ryan Tessier on 7/3/2026.
//

import SwiftUI
import Charts
import SwiftData

// MARK: - Plant Detail View

struct PlantDetailView: View {
    let plant: Plant
    
    @State private var isPairingSensorPresented = false
    @Environment(SensorMonitor.self) private var sensorMonitor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PlantImage(data: plant.image)
                    .frame(height: 187)
                
                // Sensor status indicator
                if plant.sensorIdentifier != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "sensor.fill")
                            .foregroundStyle(.green)
                        Text("Sensor Connected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
            
            if plant.sensorIdentifier != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { @MainActor in
                            sensorMonitor.updateAllMeasurements()
                        }
                    } label: {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        
    }
}

// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Plant.self, configurations: config)
        let sensorMonitor = SensorMonitor(modelContainer: container)
        
        // Create a plant with sample measurements
        let species = Species(
            scientificName: "Peperomia polybotrya",
            healthySoilMoistureRange: 15...60,
            healthyLightRange: 1500...6000,
            healthyTemperatureRange: 18...24,
            healthyHumidityRange: 40...60
        )
        
        let plant = Plant(
            name: "Pepe",
            species: species,
            image: UIImage(named: "Peperomia")?.jpegData(compressionQuality: 0.8)
        )
        
        // Add sample soil moisture measurements over the past week
        let now = Date()
        for dayOffset in stride(from: -7, through: 0, by: 1) {
            for hour in [0, 6, 12, 18] {
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: now),
                   let measurementDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                    // Simulate moisture values: gradually decreasing then watered
                    let baseValue = dayOffset < -2 ? 55 : 30 + (dayOffset * 5)
                    let variance = Int.random(in: -5...5)
                    let moistureValue = max(10, min(70, baseValue + variance))
                    
                    plant.soilMoistureMeasurements.append(
                        SoilMoistureMeasurement(value: moistureValue, timestamp: measurementDate)
                    )
                }
            }
        }
        
        // Add sample light measurements
        for dayOffset in stride(from: -7, through: 0, by: 1) {
            for hour in [8, 10, 12, 14, 16, 18] {
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: now),
                   let measurementDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                    // Simulate light levels: higher at midday
                    let hourFactor = hour == 12 || hour == 14 ? 1.2 : (hour == 8 || hour == 18 ? 0.6 : 1.0)
                    let baseLight = Int(Double(3000) * hourFactor)
                    let variance = Int.random(in: -300...300)
                    let lightValue = max(500, min(7000, baseLight + variance))
                    
                    plant.lightMeasurements.append(
                        LightMeasurement(value: lightValue, timestamp: measurementDate)
                    )
                }
            }
        }
        
        return NavigationStack {
            PlantDetailView(plant: plant)
                .environment(sensorMonitor)
        }
    } catch {
        fatalError("Failed to create preview: \(error.localizedDescription)")
    }
}

