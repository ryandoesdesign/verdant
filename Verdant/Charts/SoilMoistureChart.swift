//
//  MoistureChart.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import SwiftUI
import Charts
import SwiftData

@Model
class SoilMoistureMeasurement {
    var id: UUID = UUID()
    var value: Int
    var timestamp: Date
    
    init(value: Int, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
}

struct SoilMoistureChart: View {
    let healthySaturation: ClosedRange<Int>
    let currentCycleMeasurements: [SoilMoistureMeasurement]
    
    var body: some View {
        if currentCycleMeasurements.isEmpty {
            ContentUnavailableView(
                "No Measurements Yet",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Soil moisture data will appear here once measurements begin.")
            )
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        } else {
            Chart {
                RectangleMark(
                    xStart: .value("Start", currentCycleMeasurements.min(by: { $0.timestamp < $1.timestamp })!.timestamp),
                    xEnd: .value("End", currentCycleMeasurements.max(by: { $0.timestamp < $1.timestamp })!.timestamp),
                    yStart: .value("Minimum healthy saturation", healthySaturation.lowerBound),
                    yEnd: .value("Maximum healthy saturation", healthySaturation.upperBound)
                )
                .foregroundStyle(by: .value("Legend", "Healthy range"))
                
                ForEach(currentCycleMeasurements) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Saturation", measurement.value),
                        series: .value("Cycle", "Current")
                    )
                    .foregroundStyle(Color.accentColor)
                    
                    // Highlight the most recent point
                    if measurement == currentCycleMeasurements.max(by: { first, second in first.timestamp < second.timestamp }) {
                        PointMark(
                            x: .value("Time", measurement.timestamp),
                            y: .value("Saturation", measurement.value)
                        )
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartForegroundStyleScale(["Healthy range": Color("HealthyRangeFill")])
            .frame(maxHeight: 100)
        }
    }
}

#Preview("With Measurements") {
    let moistureMeasurements = [
        SoilMoistureMeasurement(value: 24, timestamp: Date()),
        SoilMoistureMeasurement(value: 66, timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!),
    ]
    let healthySaturation = 30...70
    
    SoilMoistureChart(
        healthySaturation: healthySaturation,
        currentCycleMeasurements: moistureMeasurements
    )
    .padding()
}

#Preview("Empty State") {
    let healthySaturation = 30...70
    
    SoilMoistureChart(
        healthySaturation: healthySaturation,
        currentCycleMeasurements: []
    )
    .padding()
}

