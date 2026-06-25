//
//  RainTrackerWidgetBundle.swift
//  RainTrackerWidget
//
//  Created by Nick Haberman on 6/24/26.
//

import WidgetKit
import SwiftUI

@main
struct RainTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RainTrackerWidget()
        RainTotalsWidget()
        RainAddWidget()
        RainAddControlWidget()
    }
}
