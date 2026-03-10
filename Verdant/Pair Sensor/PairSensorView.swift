//
//  PairSensorView.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData
import HomeKit

// Coordinator class to handle HMHomeManager delegate callbacks
class HomeKitCoordinator: NSObject, HMHomeManagerDelegate {
    var onHomesDidUpdate: (() -> Void)?
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        onHomesDidUpdate?()
    }
}

struct PairSensorView: View {
    let plant: Plant
    
    @State private var availableAccessories: [HMAccessory] = []
    @State private var homeManager = HMHomeManager()
    @State private var coordinator = HomeKitCoordinator()
    @State private var isLoading = true
    
    @State private var selectedSensor: HMAccessory? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SensorMonitor.self) private var sensorMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Find your sensor")
                    .font(Font.largeTitle.bold())
                Text("Choose the sensor you will be using to monitor \(plant.name).")
            }
            
            if isLoading {
                ProgressView("Loading accessories...")
            } else if availableAccessories.isEmpty {
                ContentUnavailableView {
                    Label("No Sensors", systemImage: "sensor.fill")
                } description: {
                    Text("No compatible sensors found. Make sure your sensors are paired in the Home app.")
                }
            } else {
                ForEach(availableAccessories, id: \.uniqueIdentifier) { accessory in
                    Button {
                        selectedSensor = accessory
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay {
                                    Image(systemName: "sensor")
                                        .resizable()
                                        .scaledToFit()
                                        .padding()
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 48, height: 48)
                                .aspectRatio(contentMode: .fill)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(accessory.name)
                                    .font(.headline)
                                if let room = accessory.room {
                                    Text(room.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            Spacer()
                            
                            if (selectedSensor?.uniqueIdentifier == accessory.uniqueIdentifier) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            // Set up the coordinator callback
            coordinator.onHomesDidUpdate = {
                discoverAccessories()
            }
            
            // Set the delegate
            homeManager.delegate = coordinator
            
            // If homes are already loaded, discover immediately
            if !homeManager.homes.isEmpty {
                discoverAccessories()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                }
            }
        }
        
        Button {
            if let selectedSensor {
                assign(selectedSensor, to: plant)
                dismiss()
            }
        } label: {
            Text("Pair")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .disabled(selectedSensor == nil)
    }
    
    func discoverAccessories() {
        // Step 1: Check if we have any homes available
        guard let home = homeManager.homes.first else {
            print("No homes available")
            isLoading = false
            return
        }
        
        // Step 2: Get all accessories from the home
        let allAccessories = home.accessories
        
        // Step 3: Filter for humidity sensors (and related environmental sensors)
        // We're looking for accessories that have humidity, temperature, or soil moisture characteristics
        availableAccessories = allAccessories.filter { accessory in
            // Check if the accessory has any relevant services
            for service in accessory.services {
                // Look for environment sensors (humidity, temperature, etc.)
                if service.serviceType == HMServiceTypeHumiditySensor ||
                   service.serviceType == HMServiceTypeTemperatureSensor {
                    return true
                }
                
                // You can also check for characteristics within services
                for characteristic in service.characteristics {
                    if characteristic.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity ||
                       characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature {
                        return true
                    }
                }
            }
            return false
        }
        
        isLoading = false
        print("Found \(availableAccessories.count) compatible accessories")
    }
    
    func assign(_ accessory: HMAccessory, to plant: Plant) {
        // Store accessory.uniqueIdentifier on the Plant model
        plant.sensorIdentifier = accessory.uniqueIdentifier
        
        // Save the context
        try? modelContext.save()
        
        // Restart monitoring to include the newly paired sensor
        Task { @MainActor in
            sensorMonitor.startMonitoring()
        }
    }
}
