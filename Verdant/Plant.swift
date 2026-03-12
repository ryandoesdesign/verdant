//
//  Plant.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import Foundation
import SwiftData

// MARK: - Sensor Status

enum SensorStatus: String, Codable {
    case connected
    case notResponding
    case notFound
    
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .notResponding: return "Not Responding"
        case .notFound: return "Not Found"
        }
    }
    
    var systemImage: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .notResponding: return "exclamationmark.triangle.fill"
        case .notFound: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .connected: return "green"
        case .notResponding: return "orange"
        case .notFound: return "orange"
        }
    }
}

@Model
class Species {
    @Attribute(.unique) var scientificName: String
    
    // Soil moisture (%)
    var healthySoilMoistureRange: ClosedRange<Int>
    
    // Light (lux)
    var healthyLightRange: ClosedRange<Int>
    
    // Temperature (°C)
    var healthyTemperatureRange: ClosedRange<Int>
    
    // Humidity (%)
    var healthyHumidityRange: ClosedRange<Int>
    
    init(
        scientificName: String,
        healthySoilMoistureRange: ClosedRange<Int>,
        healthyLightRange: ClosedRange<Int>,
        healthyTemperatureRange: ClosedRange<Int>,
        healthyHumidityRange: ClosedRange<Int>
    ) {
        self.scientificName = scientificName
        self.healthySoilMoistureRange = healthySoilMoistureRange
        self.healthyLightRange = healthyLightRange
        self.healthyTemperatureRange = healthyTemperatureRange
        self.healthyHumidityRange = healthyHumidityRange
    }
}

@Model
class Plant {
    var name: String
    var species: Species
    
    @Relationship(deleteRule: .cascade)
    var soilMoistureMeasurements: [SoilMoistureMeasurement] = []
    
    @Relationship(deleteRule: .cascade)
    var lightMeasurements: [LightMeasurement] = []
    
    @Attribute(.externalStorage)
    var image: Data? = nil
    
    // HomeKit accessory unique identifier
    var sensorIdentifier: UUID? = nil
    
    // Sensor connection status (stored as raw value)
    private var sensorStatusRawValue: String?
    
    // Sensor connection status (computed property)
    var sensorStatus: SensorStatus? {
        get {
            guard let rawValue = sensorStatusRawValue else { return nil }
            return SensorStatus(rawValue: rawValue)
        }
        set {
            sensorStatusRawValue = newValue?.rawValue
        }
    }
    
    // Last time the sensor was successfully connected
    var lastSuccessfulConnection: Date? = nil
    
    init(name: String, species: Species, image: Data? = nil) {
        self.name = name
        self.species = species
        self.image = image
    }
}
