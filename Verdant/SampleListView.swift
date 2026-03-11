//
//  SampleListView.swift
//  Verdant
//
//  Created by Ryan Tessier on 11/3/2026.
//

import SwiftUI

struct SampleListView: View {
    let samples: [SoilMoistureMeasurement]
    let plantName: String
    
    var body: some View {
        List(samples.sorted(by: { $0.timestamp > $1.timestamp })) { sample in
            HStack {
                Text(sample.value.formatted())
                Spacer()
                Text(sample.timestamp.formatted())
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Soil Moisture Samples")
        .navigationSubtitle(plantName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
