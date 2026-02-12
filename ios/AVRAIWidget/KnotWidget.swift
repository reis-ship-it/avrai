// KnotWidget.swift
//
// Home screen widget displaying the user's personality knot.
// Shows a simplified knot visualization with archetype name.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct KnotEntry: TimelineEntry {
    let date: Date
    let crossingNumber: Int
    let writhe: Double
    let bridgeNumber: Int
    let archetypeName: String?
    let hasData: Bool
    
    static var placeholder: KnotEntry {
        KnotEntry(
            date: Date(),
            crossingNumber: 5,
            writhe: 1.0,
            bridgeNumber: 2,
            archetypeName: "Explorer",
            hasData: true
        )
    }
    
    static var empty: KnotEntry {
        KnotEntry(
            date: Date(),
            crossingNumber: 0,
            writhe: 0,
            bridgeNumber: 0,
            archetypeName: nil,
            hasData: false
        )
    }
}

// MARK: - Timeline Provider

struct KnotProvider: TimelineProvider {
    private let appGroupId = "group.com.avrai.app"
    
    func placeholder(in context: Context) -> KnotEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (KnotEntry) -> Void) {
        completion(loadKnotData() ?? .placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<KnotEntry>) -> Void) {
        let entry = loadKnotData() ?? .empty
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadKnotData() -> KnotEntry? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.dictionary(forKey: "widget_knot_data") else {
            return nil
        }
        
        guard let crossingNumber = data["crossingNumber"] as? Int,
              let writhe = data["writhe"] as? Double,
              let bridgeNumber = data["bridgeNumber"] as? Int else {
            return nil
        }
        
        return KnotEntry(
            date: Date(),
            crossingNumber: crossingNumber,
            writhe: writhe,
            bridgeNumber: bridgeNumber,
            archetypeName: data["archetypeName"] as? String,
            hasData: true
        )
    }
}

// MARK: - Widget View

struct KnotWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: KnotEntry
    
    var body: some View {
        if entry.hasData {
            contentView
        } else {
            emptyView
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 8) {
            // Knot visualization (simplified)
            KnotVisualization(
                crossingNumber: entry.crossingNumber,
                writhe: entry.writhe
            )
            .frame(width: knotSize, height: knotSize)
            
            if let archetype = entry.archetypeName {
                Text(archetype)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            // iOS 26 Liquid Glass effect
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color.black.opacity(0.8)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.hexagonpath")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("Open AVRAI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.8)
        }
    }
    
    private var knotSize: CGFloat {
        switch family {
        case .systemSmall:
            return 60
        case .systemMedium:
            return 80
        default:
            return 100
        }
    }
}

// MARK: - Knot Visualization

struct KnotVisualization: View {
    let crossingNumber: Int
    let writhe: Double
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.35
            
            // Draw glow
            let glowPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(glowPath, with: .color(Color.green.opacity(0.3)))
            
            // Draw knot loops based on crossing number
            let loopCount = min(crossingNumber, 8)
            for i in 0..<loopCount {
                let angle = Double(i) * (2 * .pi / Double(loopCount))
                let loopRadius = radius * 0.6
                let loopCenter = CGPoint(
                    x: center.x + cos(angle) * loopRadius * 0.3,
                    y: center.y + sin(angle) * loopRadius * 0.3
                )
                
                let loopPath = Path(ellipseIn: CGRect(
                    x: loopCenter.x - loopRadius * 0.5,
                    y: loopCenter.y - loopRadius * 0.5,
                    width: loopRadius,
                    height: loopRadius
                ))
                
                context.stroke(loopPath, with: .color(Color.green), lineWidth: 2)
            }
            
            // Draw center point
            let centerPath = Path(ellipseIn: CGRect(
                x: center.x - 3,
                y: center.y - 3,
                width: 6,
                height: 6
            ))
            context.fill(centerPath, with: .color(Color.green))
        }
    }
}

// MARK: - Widget Configuration

struct KnotWidget: Widget {
    let kind: String = "KnotWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KnotProvider()) { entry in
            KnotWidgetView(entry: entry)
        }
        .configurationDisplayName("My Knot")
        .description("View your personality knot")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    KnotWidget()
} timeline: {
    KnotEntry.placeholder
    KnotEntry.empty
}
