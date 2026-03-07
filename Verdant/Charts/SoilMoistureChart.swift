//
//  MoistureChart.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import SwiftUI
import Charts

struct SoilMoistureMeasurement: Identifiable, Equatable {
    var id: UUID = UUID()
    var value: Int
    var timestamp: Date
}

struct SoilMoistureChart: View {
    let healthySaturation: ClosedRange<Int>
    let currentCycleMeasurements: [SoilMoistureMeasurement]
    
    var body: some View {
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
        .chartForegroundStyleScale(["Healthy range": .green])
        .frame(maxHeight: 100)
    }
}

#Preview {
    let moistureMeasurements = [
        SoilMoistureMeasurement(value: 65, timestamp: Date()),
        SoilMoistureMeasurement(value: 62, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!),
        SoilMoistureMeasurement(value: 58, timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!),
        SoilMoistureMeasurement(value: 55, timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!),
        SoilMoistureMeasurement(value: 52, timestamp: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!),
        SoilMoistureMeasurement(value: 48, timestamp: Calendar.current.date(byAdding: .hour, value: -10, to: Date())!),
        SoilMoistureMeasurement(value: 45, timestamp: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!),
        SoilMoistureMeasurement(value: 42, timestamp: Calendar.current.date(byAdding: .hour, value: -14, to: Date())!),
        SoilMoistureMeasurement(value: 38, timestamp: Calendar.current.date(byAdding: .hour, value: -16, to: Date())!),
        SoilMoistureMeasurement(value: 35, timestamp: Calendar.current.date(byAdding: .hour, value: -18, to: Date())!),
        SoilMoistureMeasurement(value: 32, timestamp: Calendar.current.date(byAdding: .hour, value: -20, to: Date())!),
        SoilMoistureMeasurement(value: 28, timestamp: Calendar.current.date(byAdding: .hour, value: -22, to: Date())!),
        SoilMoistureMeasurement(value: 25, timestamp: Calendar.current.date(byAdding: .hour, value: -24, to: Date())!),
        SoilMoistureMeasurement(value: 22, timestamp: Calendar.current.date(byAdding: .hour, value: -26, to: Date())!),
        SoilMoistureMeasurement(value: 20, timestamp: Calendar.current.date(byAdding: .hour, value: -28, to: Date())!),
        SoilMoistureMeasurement(value: 18, timestamp: Calendar.current.date(byAdding: .hour, value: -30, to: Date())!),
        SoilMoistureMeasurement(value: 15, timestamp: Calendar.current.date(byAdding: .hour, value: -32, to: Date())!),
        SoilMoistureMeasurement(value: 14, timestamp: Calendar.current.date(byAdding: .hour, value: -34, to: Date())!),
        SoilMoistureMeasurement(value: 12, timestamp: Calendar.current.date(byAdding: .hour, value: -36, to: Date())!),
        SoilMoistureMeasurement(value: 10, timestamp: Calendar.current.date(byAdding: .hour, value: -38, to: Date())!),
    ]
    let healthySaturation = 30...70
    
    SoilMoistureChart(
        healthySaturation: healthySaturation,
        currentCycleMeasurements: moistureMeasurements
    )
    .padding()
}

