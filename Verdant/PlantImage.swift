//
//  PlantImage.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI

struct PlantImage: View {
    let plant: Plant
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageData = plant.image,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6))
                        .overlay {
                            Image(systemName: "leaf")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.secondary)
                        }
                }
            }
        }
    }
}

#Preview("Plant Without Image") {
    let sampleSpecies = Species(
        scientificName: "Monstera Deliciosa",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let samplePlant = Plant(
        name: "Swiss Cheese Plant",
        species: sampleSpecies
    )
    
    PlantImage(plant: samplePlant)
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
}

#Preview("Plant With Image") {
    let sampleSpecies = Species(
        scientificName: "Ficus Lyrata",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 10000...20000,
        healthyTemperatureRange: 18...27,
        healthyHumidityRange: 60...80
    )
    
    let samplePlant = Plant(
        name: "Fiddle Leaf Fig",
        species: sampleSpecies
    )
    
    // Create a sample plant with image data
    let sampleImage = UIImage(systemName: "leaf.fill")
    samplePlant.image = sampleImage?.pngData()
    
    return PlantImage(plant: samplePlant)
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
}
