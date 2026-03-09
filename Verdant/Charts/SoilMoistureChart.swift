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
    let healthyRange: ClosedRange<Int>
    let currentCycleMeasurements: [SoilMoistureMeasurement]
    
    // Default time range for display (24 hours)
    private var timeRange: ClosedRange<Date> {
        if let minDate = currentCycleMeasurements.min(by: { $0.timestamp < $1.timestamp })?.timestamp,
           let maxDate = currentCycleMeasurements.max(by: { $0.timestamp < $1.timestamp })?.timestamp {
            return minDate...maxDate
        } else {
            // Default to showing the last 24 hours when no measurements exist
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
                yStart: .value("Minimum healthy saturation", healthyRange.lowerBound),
                yEnd: .value("Maximum healthy saturation", healthyRange.upperBound)
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
                Text("\(healthyRange.upperBound)%")
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
                Text("\(healthyRange.lowerBound)%")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }
            
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
                    .annotation {
                        Text("\(measurement.value)%")
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
    let moistureMeasurements = [
        SoilMoistureMeasurement(value: 24, timestamp: Date()),
        SoilMoistureMeasurement(value: 66, timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!),
    ]
    let healthySaturation = 30...70
    
    SoilMoistureChart(
        healthyRange: healthySaturation,
        currentCycleMeasurements: moistureMeasurements
    )
    .padding()
}

#Preview("Empty State") {
    let healthySaturation = 30...70
    
    SoilMoistureChart(
        healthyRange: healthySaturation,
        currentCycleMeasurements: []
    )
    .padding()
}

