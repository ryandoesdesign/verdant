//
//  NewLightChart.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import SwiftUI
import Charts

struct LightMeasurement: Identifiable, Equatable {
    var id: UUID = UUID()
    var value: Int
    var timestamp: Date
}

struct LightChart: View {
    let healthyIntensity: ClosedRange<Int>
    let measurements: [LightMeasurement]
    
    var body: some View {
        Chart {
            RectangleMark(
                xStart: .value("Start", measurements.min(by: { first, second in first.timestamp < second.timestamp })!.timestamp),
                xEnd: .value("End", measurements.max(by: { first, second in first.timestamp < second.timestamp })!.timestamp),
                yStart: .value("Minimum healthy intensity", healthyIntensity.lowerBound),
                yEnd: .value("Maximum healthy intensity", healthyIntensity.upperBound)
            )
            .foregroundStyle(by: .value("Legend", "Healthy range"))
            
            // Line and points for each measurement
            ForEach(measurements) { measurement in
                LineMark(
                    x: .value("Time", measurement.timestamp),
                    y: .value("Intensity", measurement.value)
                )
                .foregroundStyle(Color.accentColor)
                
                if measurement == measurements.max(by: { first, second in first.timestamp < second.timestamp }) {
                    PointMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Intensity", measurement.value)
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
    let lightMeasurements = [
        LightMeasurement(value: 2500, timestamp: Date()),
        LightMeasurement(value: 2505, timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!),
        LightMeasurement(value: 2598, timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!),
        LightMeasurement(value: 2510, timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!),
        LightMeasurement(value: 2502, timestamp: Calendar.current.date(byAdding: .minute, value: -60, to: Date())!),
        LightMeasurement(value: 2599, timestamp: Calendar.current.date(byAdding: .minute, value: -75, to: Date())!),
        LightMeasurement(value: 2501, timestamp: Calendar.current.date(byAdding: .minute, value: -90, to: Date())!),
        LightMeasurement(value: 2504, timestamp: Calendar.current.date(byAdding: .minute, value: -105, to: Date())!),
        LightMeasurement(value: 2503, timestamp: Calendar.current.date(byAdding: .minute, value: -120, to: Date())!),
        LightMeasurement(value: 2500, timestamp: Calendar.current.date(byAdding: .minute, value: -135, to: Date())!),
        LightMeasurement(value: 2597, timestamp: Calendar.current.date(byAdding: .minute, value: -150, to: Date())!),
        LightMeasurement(value: 2506, timestamp: Calendar.current.date(byAdding: .minute, value: -165, to: Date())!),
        LightMeasurement(value: 2508, timestamp: Calendar.current.date(byAdding: .minute, value: -180, to: Date())!),
        LightMeasurement(value: 2509, timestamp: Calendar.current.date(byAdding: .minute, value: -195, to: Date())!),
        LightMeasurement(value: 2507, timestamp: Calendar.current.date(byAdding: .minute, value: -210, to: Date())!),
        LightMeasurement(value: 2596, timestamp: Calendar.current.date(byAdding: .minute, value: -225, to: Date())!),
        LightMeasurement(value: 2511, timestamp: Calendar.current.date(byAdding: .minute, value: -240, to: Date())!),
        LightMeasurement(value: 2513, timestamp: Calendar.current.date(byAdding: .minute, value: -255, to: Date())!),
        LightMeasurement(value: 2515, timestamp: Calendar.current.date(byAdding: .minute, value: -270, to: Date())!),
        LightMeasurement(value: 2514, timestamp: Calendar.current.date(byAdding: .minute, value: -285, to: Date())!),
    ]
    let healthyLightIntensity = 1500...6000
    
    LightChart(
        healthyIntensity: healthyLightIntensity, measurements: lightMeasurements
    )
    .padding()
}
