// NearbySpotWidget.swift
//
// Home screen widget displaying the nearest recommended spot.
// Shows spot name, category, and distance.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SpotEntry: TimelineEntry {
    let date: Date
    let spotName: String
    let category: String
    let distance: Double
    let rating: Double
    let hasData: Bool
    
    static var placeholder: SpotEntry {
        SpotEntry(
            date: Date(),
            spotName: "Blue Bottle Coffee",
            category: "Coffee",
            distance: 0.3,
            rating: 4.5,
            hasData: true
        )
    }
    
    static var empty: SpotEntry {
        SpotEntry(
            date: Date(),
            spotName: "",
            category: "",
            distance: 0,
            rating: 0,
            hasData: false
        )
    }
}

// MARK: - Timeline Provider

struct SpotProvider: TimelineProvider {
    private let appGroupId = "group.com.avrai.app"
    
    func placeholder(in context: Context) -> SpotEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SpotEntry) -> Void) {
        completion(loadSpotData() ?? .placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpotEntry>) -> Void) {
        let entry = loadSpotData() ?? .empty
        
        // Refresh every 15 minutes for location-based data
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadSpotData() -> SpotEntry? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.dictionary(forKey: "widget_spot_data") else {
            return nil
        }
        
        guard let spotName = data["spotName"] as? String,
              let category = data["category"] as? String,
              let distance = data["distance"] as? Double,
              let rating = data["rating"] as? Double else {
            return nil
        }
        
        return SpotEntry(
            date: Date(),
            spotName: spotName,
            category: category,
            distance: distance,
            rating: rating,
            hasData: true
        )
    }
}

// MARK: - Widget View

struct SpotWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SpotEntry
    
    var body: some View {
        if entry.hasData {
            contentView
        } else {
            emptyView
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category icon
            HStack {
                Image(systemName: categoryIcon)
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Text(entry.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Distance
                Text("\(entry.distance, specifier: "%.1f") mi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Spot name
            Text(entry.spotName)
                .font(.headline)
                .lineLimit(2)
            
            // Rating
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                
                Text("\(entry.rating, specifier: "%.1f")")
                    .font(.caption)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color.black.opacity(0.85)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "mappin.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No spots nearby")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.85)
        }
    }
    
    private var categoryIcon: String {
        switch entry.category.lowercased() {
        case "coffee":
            return "cup.and.saucer.fill"
        case "restaurant":
            return "fork.knife"
        case "bar":
            return "wineglass.fill"
        case "park":
            return "leaf.fill"
        case "gym":
            return "dumbbell.fill"
        default:
            return "mappin"
        }
    }
}

// MARK: - Widget Configuration

struct NearbySpotWidget: Widget {
    let kind: String = "NearbySpotWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpotProvider()) { entry in
            SpotWidgetView(entry: entry)
        }
        .configurationDisplayName("Nearby Spot")
        .description("Your closest recommended spot")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NearbySpotWidget()
} timeline: {
    SpotEntry.placeholder
    SpotEntry.empty
}
