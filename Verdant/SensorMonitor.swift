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

// MARK: - HomeKit Async Extensions

extension HMCharacteristic {
    /// Async wrapper for reading characteristic values
    func readValueAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.readValue { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - Sensor Monitor

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
    
    // Track periodic monitoring task
    private var monitoringTask: Task<Void, Never>?
    
    // Update interval (e.g., every 5 minutes)
    private let updateInterval: Duration = .seconds(300)
    
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
        // updateAllMeasurements()
        
        // Set up periodic updates using Swift Concurrency
        monitoringTask?.cancel()
        monitoringTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: updateInterval)
                guard !Task.isCancelled else { break }
                updateAllMeasurements()
            }
        }
    }
    
    func stopMonitoring() {
        print("🛑 Stopping sensor monitoring...")
        monitoringTask?.cancel()
        monitoringTask = nil
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
            
            Task {
                await updateMeasurements(for: plant.persistentModelID, from: accessory)
            }
        }
    }
    
    @MainActor
    private func updateMeasurements(for plantID: PersistentIdentifier, from accessory: HMAccessory) async {
        let timestamp = Date()
        
        // Get all characteristics we care about
        let characteristics = accessory.services
            .flatMap { $0.characteristics }
            .filter { shouldMonitor(characteristic: $0) }
        
        // Read all characteristics concurrently
        await withTaskGroup(of: Void.self) { group in
            for characteristic in characteristics {
                group.addTask {
                    do {
                        try await characteristic.readValueAsync()
                        
                        await MainActor.run {
                            let context = self.modelContainer.mainContext
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
                            
                            // Save after processing each characteristic
                            try? context.save()
                        }
                    } catch {
                        print("⚠️ Failed to read characteristic: \(error)")
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
