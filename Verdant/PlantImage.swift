//
//  PlantImage.swift
//  Verdant
//
//  Created by Ryan Tessier on 9/3/2026.
//

import SwiftUI

struct PlantImage: View {
    let data: Data?
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageData = data,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay {
                            Image(systemName: "leaf")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .foregroundStyle(.secondary)
                        }
                }
            }
        }
    }
}

#Preview("Plant Without Image") {
    PlantImage(data: nil)
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
}

#Preview("Plant With Image") {
    // Create a sample plant with image data
    let sampleImageData = UIImage(systemName: "leaf.fill")!.pngData()
    
    PlantImage(data: sampleImageData)
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
}
