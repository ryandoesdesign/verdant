//
//  PlantDetailView.swift
//  Verdant
//
//  Created by Ryan Tessier on 7/3/2026.
//

import SwiftUI
import Charts

// MARK: - Supporting Types

struct MeasurementPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Plant Detail View

struct PlantDetailView: View {
    let plantName = "Pepe"
    let speciesName = "Peperomia polybotrya"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("plant")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 187)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                        Text("Soil Moisture")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    
                    SoilMoistureChart(
                        healthySaturation: 15...60,
                        currentCycleMeasurements: [
                            SoilMoistureMeasurement(value: 8, timestamp: Date()),
                            SoilMoistureMeasurement(value: 12, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!),
                            SoilMoistureMeasurement(value: 14, timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!),
                            SoilMoistureMeasurement(value: 15, timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!),
                            SoilMoistureMeasurement(value: 18, timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!),
                            SoilMoistureMeasurement(value: 20, timestamp: Calendar.current.date(byAdding: .hour, value: -10, to: Date())!),
                            SoilMoistureMeasurement(value: 22, timestamp: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!),
                            SoilMoistureMeasurement(value: 25, timestamp: Calendar.current.date(byAdding: .hour, value: -14, to: Date())!),
                            SoilMoistureMeasurement(value: 28, timestamp: Calendar.current.date(byAdding: .hour, value: -16, to: Date())!),
                            SoilMoistureMeasurement(value: 38, timestamp: Calendar.current.date(byAdding: .hour, value: -18, to: Date())!),
                            SoilMoistureMeasurement(value: 40, timestamp: Calendar.current.date(byAdding: .hour, value: -20, to: Date())!),
                            SoilMoistureMeasurement(value: 44, timestamp: Calendar.current.date(byAdding: .hour, value: -22, to: Date())!),
                            SoilMoistureMeasurement(value: 49, timestamp: Calendar.current.date(byAdding: .hour, value: -24, to: Date())!),
                            SoilMoistureMeasurement(value: 59, timestamp: Calendar.current.date(byAdding: .hour, value: -26, to: Date())!),
                            SoilMoistureMeasurement(value: 60, timestamp: Calendar.current.date(byAdding: .hour, value: -28, to: Date())!),
                            SoilMoistureMeasurement(value: 60, timestamp: Calendar.current.date(byAdding: .hour, value: -30, to: Date())!),
                            SoilMoistureMeasurement(value: 60, timestamp: Calendar.current.date(byAdding: .hour, value: -32, to: Date())!),
                            SoilMoistureMeasurement(value: 61, timestamp: Calendar.current.date(byAdding: .hour, value: -34, to: Date())!),
                            SoilMoistureMeasurement(value: 61, timestamp: Calendar.current.date(byAdding: .hour, value: -36, to: Date())!),
                            SoilMoistureMeasurement(value: 66, timestamp: Calendar.current.date(byAdding: .hour, value: -38, to: Date())!),
                        ]
                    )
                    
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                        Text("Light")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    
                    LightChart(
                        healthyIntensity: 1500...6000,
                        measurements: [
                            LightMeasurement(value: 2750, timestamp: Date()),
                            LightMeasurement(value: 3000, timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!),
                            LightMeasurement(value: 3200, timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!),
                            LightMeasurement(value: 3600, timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!),
                        ]
                    )
                    
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(plantName)
        .navigationSubtitle(speciesName)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlantDetailView()
    }
}
