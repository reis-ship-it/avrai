// ReservationWidget.swift
//
// Home screen widget displaying upcoming reservation.
// Shows spot name, time, and countdown.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ReservationEntry: TimelineEntry {
    let date: Date
    let spotName: String
    let reservationTime: Date
    let partySize: Int
    let status: String
    let hasData: Bool
    
    var minutesUntil: Int {
        let interval = reservationTime.timeIntervalSince(Date())
        return max(0, Int(interval / 60))
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reservationTime)
    }
    
    static var placeholder: ReservationEntry {
        ReservationEntry(
            date: Date(),
            spotName: "Blue Bottle Coffee",
            reservationTime: Date().addingTimeInterval(30 * 60),
            partySize: 2,
            status: "confirmed",
            hasData: true
        )
    }
    
    static var empty: ReservationEntry {
        ReservationEntry(
            date: Date(),
            spotName: "",
            reservationTime: Date(),
            partySize: 0,
            status: "",
            hasData: false
        )
    }
}

// MARK: - Timeline Provider

struct ReservationProvider: TimelineProvider {
    private let appGroupId = "group.com.avrai.app"
    
    func placeholder(in context: Context) -> ReservationEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ReservationEntry) -> Void) {
        completion(loadReservationData() ?? .placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ReservationEntry>) -> Void) {
        let entry = loadReservationData() ?? .empty
        
        // Refresh every 5 minutes for countdown accuracy
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadReservationData() -> ReservationEntry? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.dictionary(forKey: "widget_reservation_data") else {
            return nil
        }
        
        guard let spotName = data["spotName"] as? String,
              let reservationTimeStr = data["reservationTime"] as? String,
              let partySize = data["partySize"] as? Int,
              let status = data["status"] as? String else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        guard let reservationTime = formatter.date(from: reservationTimeStr) else {
            return nil
        }
        
        // Don't show past reservations
        guard reservationTime > Date() else {
            return nil
        }
        
        return ReservationEntry(
            date: Date(),
            spotName: spotName,
            reservationTime: reservationTime,
            partySize: partySize,
            status: status,
            hasData: true
        )
    }
}

// MARK: - Widget View

struct ReservationWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ReservationEntry
    
    var body: some View {
        if entry.hasData {
            contentView
        } else {
            emptyView
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status badge
            HStack {
                statusBadge
                Spacer()
                Text(entry.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Spot name
            Text(entry.spotName)
                .font(.headline)
                .lineLimit(2)
            
            // Countdown and party size
            HStack {
                // Countdown
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.minutesUntil)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Party size
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(entry.partySize)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
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
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No reservations")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.85)
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let (color, icon) = statusStyle
        
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(entry.status.capitalized)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
    
    private var statusStyle: (Color, String) {
        switch entry.status.lowercased() {
        case "confirmed":
            return (.green, "checkmark.circle.fill")
        case "pending":
            return (.orange, "clock.fill")
        case "ready":
            return (.blue, "bell.fill")
        default:
            return (.gray, "circle.fill")
        }
    }
}

// MARK: - Widget Configuration

struct ReservationWidget: Widget {
    let kind: String = "ReservationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReservationProvider()) { entry in
            ReservationWidgetView(entry: entry)
        }
        .configurationDisplayName("Reservation")
        .description("Your next reservation")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    ReservationWidget()
} timeline: {
    ReservationEntry.placeholder
    ReservationEntry.empty
}
