//
//  ContentView.swift
//  Verdant
//
//  Created by Ryan Tessier on 7/3/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PlantDetailView(plant: Plant(
                name: "Pepe",
                species: Species(
                    scientificName: "Peperomia polybotrya",
                    healthySoilMoistureRange: 40...60,
                    healthyLightRange: 10000...20000,
                    healthyTemperatureRange: 18...24,
                    healthyHumidityRange: 40...60
                )
            ))
        }
    }
}

#Preview {
    ContentView()
}
