//
//  TrailGuideWidgetBundle.swift
//  TrailGuideWidget
//
//  Created by MarkCnw on 23/6/2569 BE.
//

import WidgetKit
import SwiftUI

@main
struct TrailGuideWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrailGuideWidget()
        TrailGuideWidgetControl()
        TrailGuideWidgetLiveActivity()
    }
}
