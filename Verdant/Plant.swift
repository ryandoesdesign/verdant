//
//  Plant.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import Foundation
import SwiftData

@Model
class Species {
    var scientificName: String
    
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
    
    init(name: String, species: Species) {
        self.name = name
        self.species = species
    }
}
