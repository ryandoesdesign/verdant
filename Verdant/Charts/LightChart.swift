//
//  NewLightChart.swift
//  Verdant
//
//  Created by Ryan Tessier on 8/3/2026.
//

import SwiftUI
import Charts
import SwiftData

@Model
class LightMeasurement {
    var id: UUID = UUID()
    var value: Int
    var timestamp: Date
    
    init(value: Int, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
}

struct LightChart: View {
    let healthyRange: ClosedRange<Int>
    let measurements: [LightMeasurement]
    
    // Default time range for display (24 hours)
    private var timeRange: ClosedRange<Date> {
        if let minDate = measurements.min(by: { $0.timestamp < $1.timestamp })?.timestamp,
           let maxDate = measurements.max(by: { $0.timestamp < $1.timestamp })?.timestamp {
            return minDate...maxDate
        } else {
            let now = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            return yesterday...now
        }
    }
    
    var body: some View {
        Chart {
            RectangleMark(
                xStart: .value("Start", timeRange.lowerBound),
                xEnd: .value("End", timeRange.upperBound),
                yStart: .value("Minimum healthy intensity", healthyRange.lowerBound),
                yEnd: .value("Maximum healthy intensity", healthyRange.upperBound)
            )
            .foregroundStyle(by: .value("Legend", "Healthy range"))
            
            RuleMark(
                xStart: .value("Start", timeRange.lowerBound),
                xEnd: .value("End", timeRange.upperBound),
                y: .value("Maximum healthy saturation", healthyRange.upperBound)
            )
            .foregroundStyle(Color.secondary)
            .lineStyle(StrokeStyle(lineWidth: 1))
            .annotation {
                Text("\(healthyRange.upperBound) lux")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }
            
            RuleMark(
                xStart: .value("Start", timeRange.lowerBound),
                xEnd: .value("End", timeRange.upperBound),
                y: .value("Mimimum healthy saturation", healthyRange.lowerBound)
            )
            .foregroundStyle(Color.secondary)
            .lineStyle(StrokeStyle(lineWidth: 1))
            .annotation(position: .bottom) {
                Text("\(healthyRange.lowerBound) lux")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }
            
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
                    .annotation {
                        Text("\(measurement.value) lux")
                            .font(Font.caption.bold())
                            .foregroundStyle(Color.accent)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartForegroundStyleScale(["Healthy range": Color("HealthyRangeFill")])
    }
}

#Preview("With Measurements") {
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
        healthyRange: healthyLightIntensity,
        measurements: lightMeasurements
    )
    .padding()
}
#Preview("Empty State") {
    let healthyLightIntensity = 1500...6000
    
    LightChart(
        healthyRange: healthyLightIntensity,
        measurements: []
    )
    .padding()
}

