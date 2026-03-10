//
//  SensorMonitor.swift
//  Verdant
//
//  Created by Ryan Tessier on 10/3/2026.
//

import Foundation
import HomeKit
import SwiftData
import Observation

/// Monitors HomeKit sensors and updates plant measurements in SwiftData
///
/// This class manages the lifecycle of sensor monitoring:
/// 1. Discovers HomeKit accessories paired with plants
/// 2. Enables notifications for sensor characteristics (humidity, temperature, light)
/// 3. Periodically reads sensor values (every 5 minutes by default)
/// 4. Immediately updates when sensors send notifications
/// 5. Saves measurements to SwiftData for each plant
///
/// Usage:
/// - Initialize once in VerdantApp with the model container
/// - Access via @Environment in views
/// - Call `startMonitoring()` after pairing new sensors
/// - Call `updateAllMeasurements()` to manually refresh
@Observable
class SensorMonitor: NSObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    private let homeManager = HMHomeManager()
    private let modelContainer: ModelContainer
    private var monitoredAccessories: Set<UUID> = []
    
    // Track timer for periodic updates
    private var updateTimer: Timer?
    
    // Update interval (e.g., every 5 minutes)
    private let updateInterval: TimeInterval = 300 // 5 minutes
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
        
        homeManager.delegate = self
        
        // Start monitoring after a short delay to ensure HomeKit is ready
        Task {
            try? await Task.sleep(for: .seconds(1))
            await startMonitoring()
        }
    }
    
    // MARK: - Monitoring Control
    
    @MainActor
    func startMonitoring() {
        print("🔍 Starting sensor monitoring...")
        
        // Fetch all plants with paired sensors
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Plant>()
        
        guard let plants = try? context.fetch(descriptor) else {
            print("⚠️ Failed to fetch plants")
            return
        }
        
        // Collect all sensor identifiers
        let pairedSensorIds = plants.compactMap { $0.sensorIdentifier }
        
        print("📱 Found \(pairedSensorIds.count) paired sensors")
        
        // Find and monitor accessories
        guard let home = homeManager.homes.first else {
            print("⚠️ No HomeKit home available")
            return
        }
        
        for sensorId in pairedSensorIds {
            if let accessory = home.accessories.first(where: { $0.uniqueIdentifier == sensorId }) {
                startMonitoring(accessory: accessory)
            }
        }
        
        // Initial update
        updateAllMeasurements()
        
        // Set up periodic updates
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateAllMeasurements()
            }
        }
    }
    
    func stopMonitoring() {
        print("🛑 Stopping sensor monitoring...")
        updateTimer?.invalidate()
        updateTimer = nil
        monitoredAccessories.removeAll()
    }
    
    // MARK: - Accessory Monitoring
    
    private func startMonitoring(accessory: HMAccessory) {
        guard !monitoredAccessories.contains(accessory.uniqueIdentifier) else {
            return
        }
        
        accessory.delegate = self
        monitoredAccessories.insert(accessory.uniqueIdentifier)
        
        // Enable notifications for all relevant characteristics
        for service in accessory.services {
            for characteristic in service.characteristics {
                if shouldMonitor(characteristic: characteristic) {
                    characteristic.enableNotification(true) { error in
                        if let error = error {
                            print("⚠️ Failed to enable notifications for \(characteristic.localizedDescription): \(error)")
                        } else {
                            print("✅ Enabled notifications for \(characteristic.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        print("✅ Started monitoring accessory: \(accessory.name)")
    }
    
    private func shouldMonitor(characteristic: HMCharacteristic) -> Bool {
        // Monitor humidity, temperature, and light sensors
        return characteristic.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity ||
               characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature ||
               characteristic.metadata?.format == HMCharacteristicMetadataFormatInt ||
               characteristic.metadata?.format == HMCharacteristicMetadataFormatFloat
    }
    
    // MARK: - Measurement Updates
    
    @MainActor
    func updateAllMeasurements() {
        print("📊 Updating measurements...")
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Plant>()
        
        guard let plants = try? context.fetch(descriptor) else {
            print("⚠️ Failed to fetch plants for measurement update")
            return
        }
        
        guard let home = homeManager.homes.first else {
            print("⚠️ No HomeKit home available")
            return
        }
        
        for plant in plants {
            guard let sensorId = plant.sensorIdentifier else { continue }
            guard let accessory = home.accessories.first(where: { $0.uniqueIdentifier == sensorId }) else {
                print("⚠️ Accessory not found for plant: \(plant.name)")
                continue
            }
            
            updateMeasurements(for: plant, from: accessory, context: context)
        }
        
        // Save all changes
        do {
            try context.save()
            print("✅ Measurements saved successfully")
        } catch {
            print("❌ Failed to save measurements: \(error)")
        }
    }
    
    @MainActor
    func updateMeasurements(for plant: Plant, from accessory: HMAccessory, context: ModelContext) {
        let timestamp = Date()
        let plantID = plant.persistentModelID
        
        for service in accessory.services {
            for characteristic in service.characteristics {
                // Read the current value
                characteristic.readValue { [weak self] error in
                    guard let self else { return }
                    
                    if let error = error {
                        print("⚠️ Failed to read characteristic: \(error)")
                        return
                    }
                    
                    Task { @MainActor in
                        // Get the main context without capturing the parameter
                        let context = self.modelContainer.mainContext
                        
                        // Refetch the plant using its ID to avoid capturing non-Sendable type
                        guard let plant = context.model(for: plantID) as? Plant else {
                            print("⚠️ Failed to refetch plant")
                            return
                        }
                        
                        self.processCharacteristic(
                            characteristic,
                            for: plant,
                            timestamp: timestamp,
                            context: context
                        )
                    }
                }
            }
        }
    }
    
    @MainActor
    private func processCharacteristic(
        _ characteristic: HMCharacteristic,
        for plant: Plant,
        timestamp: Date,
        context: ModelContext
    ) {
        guard let value = characteristic.value else { return }
        
        switch characteristic.characteristicType {
        case HMCharacteristicTypeCurrentRelativeHumidity:
            // Humidity is typically used as a proxy for soil moisture in plant sensors
            if let humidity = value as? Double {
                let measurement = SoilMoistureMeasurement(
                    value: Int(humidity),
                    timestamp: timestamp
                )
                plant.soilMoistureMeasurements.append(measurement)
                print("💧 Added soil moisture: \(Int(humidity))% for \(plant.name)")
            }
            
        case HMCharacteristicTypeCurrentTemperature:
            // You could add temperature tracking here if needed
            if let temp = value as? Double {
                print("🌡️ Temperature: \(temp)°C for \(plant.name)")
            }
            
        default:
            // Check if this might be a light sensor (lux values)
            // Many HomeKit light sensors report as custom characteristics
            if let lightValue = value as? Int, lightValue > 0 && lightValue < 100000 {
                let measurement = LightMeasurement(
                    value: lightValue,
                    timestamp: timestamp
                )
                plant.lightMeasurements.append(measurement)
                print("☀️ Added light: \(lightValue) lux for \(plant.name)")
            } else if let lightValue = value as? Double, lightValue > 0 && lightValue < 100000 {
                let measurement = LightMeasurement(
                    value: Int(lightValue),
                    timestamp: timestamp
                )
                plant.lightMeasurements.append(measurement)
                print("☀️ Added light: \(Int(lightValue)) lux for \(plant.name)")
            }
        }
    }
    
    // MARK: - HMHomeManagerDelegate
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("🏠 HomeKit homes updated")
        Task { @MainActor in
            startMonitoring()
        }
    }
    
    // MARK: - HMAccessoryDelegate
    
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        print("🔔 Characteristic updated: \(characteristic.localizedDescription) = \(characteristic.value ?? "nil")")
        
        // When a characteristic updates, immediately save the new measurement
        Task { @MainActor in
            let context = modelContainer.mainContext
            let accessoryId = accessory.uniqueIdentifier
            let descriptor = FetchDescriptor<Plant>(
                predicate: #Predicate { plant in
                    plant.sensorIdentifier == accessoryId
                }
            )
            
            guard let plants = try? context.fetch(descriptor),
                  let plant = plants.first else {
                print("⚠️ No plant found for accessory: \(accessory.name)")
                return
            }
            
            let timestamp = Date()
            processCharacteristic(characteristic, for: plant, timestamp: timestamp, context: context)
            
            // Save immediately
            try? context.save()
        }
    }
    
    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        print("📡 Accessory reachability changed: \(accessory.name) - reachable: \(accessory.isReachable)")
    }
}
