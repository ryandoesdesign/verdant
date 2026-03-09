//
//  AddPhotoView.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddPhotoView : View {
    let name: String
    let species: Species
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismissSheet) private var dismissSheet
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a photo of your plant")
                        .font(Font.largeTitle.bold())
                    Text("But only if you want.")
                }
                
                // Preview the selected photo
                PlantImage(data: photoData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                
                // Photo picker - automatically shows both library and camera options
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Label("Add Photo", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            
            Button {
                addPlant()
            } label: {
                Text("Add \(name)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
    }
    
    private func addPlant() {
        let newPlant = Plant(name: name, species: species, image: photoData)
        modelContext.insert(newPlant)
        
        // Save the context to persist the changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save plant: \(error)")
        }
        
        dismissSheet?()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Species.self, configurations: config)
    
    let species = Species(
        scientificName: "Peperomia obtusifolia",
        healthySoilMoistureRange: 40...60,
        healthyLightRange: 1500...3500,
        healthyTemperatureRange: 18...24,
        healthyHumidityRange: 40...60
    )
    
    return NavigationStack {
        AddPhotoView(name: "Pepe", species: species)
    }
    .modelContainer(container)
}
