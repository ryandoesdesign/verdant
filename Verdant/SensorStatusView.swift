//
//  SensorStatusView.swift
//  Verdant
//
//  Created by Ryan Tessier on 12/3/2026.
//

import SwiftUI

// MARK: - Sensor Status View

struct SensorStatusView: View {
    let plant: Plant
    @State private var showingSensorAlert = false
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        if plant.sensorIdentifier != nil {
            Button {
                if plant.sensorStatus != .connected {
                    showingSensorAlert = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sensor.fill")
                        .foregroundStyle(statusColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sensor \(plant.sensorStatus?.displayName ?? "Unknown")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let lastConnection = plant.lastSuccessfulConnection,
                           plant.sensorStatus != .connected {
                            Text("Last seen \(lastConnection.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: plant.sensorStatus?.systemImage ?? "questionmark.circle.fill")
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(plant.sensorStatus == .connected)
            .alert("Sensor \(plant.sensorStatus?.displayName ?? "Unknown")", isPresented: $showingSensorAlert) {
                Button("Open Home App") {
                    if let url = URL(string: "com.apple.Home://") {
                        openURL(url)
                    }
                }
                Button("Remove Sensor", role: .destructive) {
                    plant.sensorIdentifier = nil
                    plant.sensorStatus = nil
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var statusColor: Color {
        switch plant.sensorStatus {
        case .connected:
            return .green
        case .notResponding, .notFound:
            return .orange
        case .none:
            return .gray
        }
    }
    
    private var alertMessage: String {
        switch plant.sensorStatus {
        case .notFound:
            return "The sensor paired with \(plant.name) isn't available in HomeKit. Check that it's powered on and connected to your home."
        case .notResponding:
            return "The sensor for \(plant.name) is currently not responding. Make sure it's within range and powered on."
        default:
            return "There's an issue with the sensor for \(plant.name)."
        }
    }
}

// MARK: - Compact Sensor Status Badge

struct SensorStatusBadge: View {
    let status: SensorStatus
    
    var body: some View {
        Image(systemName: status.systemImage)
            .font(.caption)
            .foregroundStyle(badgeColor)
    }
    
    private var badgeColor: Color {
        switch status {
        case .connected:
            return .green
        case .notResponding, .notFound:
            return .orange
        }
    }
}

#Preview("Responding") {
    let species = Species(
        scientificName: "Monstera deliciosa",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let plant = Plant(name: "Monty", species: species)
    plant.sensorIdentifier = UUID()
    plant.sensorStatus = .connected
    plant.lastSuccessfulConnection = Date()
    
    return SensorStatusView(plant: plant)
        .padding()
}

#Preview("Not Responding") {
    let species = Species(
        scientificName: "Monstera deliciosa",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let plant = Plant(name: "Monty", species: species)
    plant.sensorIdentifier = UUID()
    plant.sensorStatus = .notResponding
    plant.lastSuccessfulConnection = Calendar.current.date(byAdding: .hour, value: -3, to: Date())
    
    return SensorStatusView(plant: plant)
        .padding()
}

#Preview("Not Found") {
    let species = Species(
        scientificName: "Monstera deliciosa",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let plant = Plant(name: "Monty", species: species)
    plant.sensorIdentifier = UUID()
    plant.sensorStatus = .notFound
    plant.lastSuccessfulConnection = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    
    return SensorStatusView(plant: plant)
        .padding()
}
