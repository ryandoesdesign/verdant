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
import UserNotifications

// MARK: - Sensor Monitor

/// Monitors HomeKit sensors and updates plant measurements in SwiftData
///
/// This class manages the lifecycle of sensor monitoring:
/// 1. Discovers HomeKit accessories paired with plants
/// 2. Enables notifications for sensor characteristics (humidity, temperature, light)
/// 3. Immediately updates when sensors send notifications via push
/// 4. Saves measurements to SwiftData for each plant
/// 5. Tracks sensor connection status and notifies users of persistent issues
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
    private var isHomeKitReady = false
    
    // Track when sensors were first reported as missing
    private var sensorIssueTimestamps: [UUID: Date] = [:]
    
    // Time threshold for persistent issue notifications (24 hours)
    private let persistentIssueThreshold: TimeInterval = 24 * 60 * 60
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
        
        homeManager.delegate = self
        requestNotificationAuthorization()
    }
    
    // MARK: - Notification Authorization
    
    private func requestNotificationAuthorization() {
        Task {
            do {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("􀙭 Failed to request notification authorization: \(error)")
            }
        }
    }
    
    // MARK: - Monitoring Control
    
    @MainActor
    func startMonitoring() {
        guard isHomeKitReady else {
            return
        }
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate { plant in
                plant.sensorIdentifier != nil
            }
        )
        
        guard let plants = try? context.fetch(descriptor) else {
            print("􀇿 Failed to fetch plants")
            return
        }
        
        let pairedSensorIds = plants.compactMap(\.sensorIdentifier)
        
        print("􁔊 \(pairedSensorIds.count) paired sensors")
        
        let allAccessories = homeManager.homes.flatMap { $0.accessories }

        for sensorId in pairedSensorIds {
            if let accessory = allAccessories.first(where: { $0.uniqueIdentifier == sensorId }) {
                startMonitoring(accessory: accessory)
                // Check actual reachability, not just existence
                let status: SensorStatus = accessory.isReachable ? .connected : .notResponding
                updateSensorStatus(sensorId: sensorId, status: status)
                
                if !accessory.isReachable {
                    checkForPersistentIssue(sensorId: sensorId)
                    print("􀙥 Sensor \(sensorId) found but not responding")
                }
            } else {
                // Update status silently - let UI show the state
                updateSensorStatus(sensorId: sensorId, status: .notFound)
                checkForPersistentIssue(sensorId: sensorId)
                print("􀙥 Sensor \(sensorId) not found")
            }
        }
    }
    
    @MainActor
    private func updateSensorStatus(sensorId: UUID, status: SensorStatus) {
        guard let plant = fetchPlant(with: sensorId) else { return }
        
        plant.sensorStatus = status
        
        if status == .connected {
            plant.lastSuccessfulConnection = Date()
            // Clear issue timestamp when resolved
            sensorIssueTimestamps.removeValue(forKey: sensorId)
        }
        
        // Save the status update
        try? modelContainer.mainContext.save()
    }
    
    @MainActor
    private func checkForPersistentIssue(sensorId: UUID) {
        guard let plant = fetchPlant(with: sensorId) else { return }
        
        let now = Date()
        
        // Track when this issue was first detected
        if sensorIssueTimestamps[sensorId] == nil {
            sensorIssueTimestamps[sensorId] = now
        }
        
        // Check if issue has persisted beyond threshold
        if let issueStartTime = sensorIssueTimestamps[sensorId],
           now.timeIntervalSince(issueStartTime) > persistentIssueThreshold {
            // Notify user of persistent issue
            Task {
                await notifyUserOfPersistentIssue(plantName: plant.name, sensorId: sensorId)
            }
        }
    }
    
    private func notifyUserOfPersistentIssue(plantName: String, sensorId: UUID) async {
        let content = UNMutableNotificationContent()
        content.title = "Sensor Disconnected"
        content.body = "\(plantName)'s sensor hasn't been found for 24 hours. Check your Home app to ensure it's powered on and connected."
        content.sound = .default
        content.categoryIdentifier = "SENSOR_ISSUE"
        content.userInfo = ["sensorId": sensorId.uuidString, "plantName": plantName]
        
        let request = UNNotificationRequest(
            identifier: "sensor-issue-\(sensorId.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("􀑐 Sent persistent issue notification for \(plantName)")
        } catch {
            print("􀙭 Failed to send notification: \(error)")
        }
    }
    
    func stopMonitoring() {
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
                            print("􀇿 Failed to enable notifications for \(characteristic.localizedDescription): \(error)")
                        }
                    }
                }
            }
        }
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
                        value: Int(humidity.rounded()),
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
        isHomeKitReady = true
        
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
        Task { @MainActor in
            let newStatus: SensorStatus = accessory.isReachable ? .connected : .notResponding
            updateSensorStatus(sensorId: accessory.uniqueIdentifier, status: newStatus)
            
            if !accessory.isReachable {
                checkForPersistentIssue(sensorId: accessory.uniqueIdentifier)
            }
        }
    }
}
