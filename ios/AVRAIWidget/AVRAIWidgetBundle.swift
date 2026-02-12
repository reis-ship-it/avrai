// AVRAIWidgetBundle.swift
//
// Widget bundle for AVRAI widgets.
// Contains all available widgets for the app.

import WidgetKit
import SwiftUI

@main
struct AVRAIWidgetBundle: WidgetBundle {
    var body: some Widget {
        KnotWidget()
        NearbySpotWidget()
        ReservationWidget()
    }
}
