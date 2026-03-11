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

// MARK: - Sensor Monitor

/// Monitors HomeKit sensors and updates plant measurements in SwiftData
///
/// This class manages the lifecycle of sensor monitoring:
/// 1. Discovers HomeKit accessories paired with plants
/// 2. Enables notifications for sensor characteristics (humidity, temperature, light)
/// 3. Immediately updates when sensors send notifications via push
/// 4. Saves measurements to SwiftData for each plant
///
/// Usage:
/// - Initialize once in VerdantApp with the model container
/// - Access via @Environment in views
/// - Call `startMonitoring()` after pairing new sensors
@Observable
class SensorMonitor: NSObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    private let homeManager = HMHomeManager()
    private let modelContainer: ModelContainer
    private var monitoredAccessories: Set<UUID> = []
    
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
        
        // Relying solely on HomeKit push notifications via enableNotification
    }
    
    func stopMonitoring() {
        print("🛑 Stopping sensor monitoring...")
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
        // Monitor only humidity (soil moisture proxy) and temperature
        return characteristic.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity ||
               characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature
    }
    
    // MARK: - Measurement Updates
    
    @MainActor
    private func fetchPlant(with sensorId: UUID) -> Plant? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate { plant in
                plant.sensorIdentifier == sensorId
            }
        )
        
        guard let plants = try? context.fetch(descriptor),
              let plant = plants.first else {
            return nil
        }
        
        return plant
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
                if let humidity = value as? Double {
                    let measurement = SoilMoistureMeasurement(
                        value: Int(humidity),
                        timestamp: timestamp
                    )
                    plant.soilMoistureMeasurements.append(measurement)
                    print("[\(timestamp.formatted(date: .abbreviated, time: .complete))] 􀠒 \(plant.name): \(Int(humidity.rounded()))%")
                }
            break
            default:
                print("[\(timestamp.formatted(date: .abbreviated, time: .complete))] 􂞷 \(plant.name): \(characteristic.characteristicType) not recorded")
            break
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
        let timestamp = Date()
        
        print("[\(timestamp.formatted(date: .abbreviated, time: .complete))] 􁔊 \(accessory.uniqueIdentifier): \(characteristic.localizedDescription) = \(characteristic.value ?? "—")")
        
        // When a characteristic updates, immediately save the new measurement
        Task { @MainActor in
            guard let plant = fetchPlant(with: accessory.uniqueIdentifier) else {
                print("No plant found for accessory: \(accessory.name)")
                return
            }
            
            let context = modelContainer.mainContext
            processCharacteristic(characteristic, for: plant, timestamp: timestamp, context: context)
            
            // Save immediately
            try? context.save()
        }
    }
    
    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        print("📡 Accessory reachability changed: \(accessory.name) - reachable: \(accessory.isReachable)")
    }
}
