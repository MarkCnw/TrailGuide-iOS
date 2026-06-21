//
//  TripHistory.swift
//  TrailGuide-iOs
//
//  Created by MarkCnw on 20/6/2569 BE.
//

import Foundation
import CoreLocation


struct TripHistory {
    let id: Int
    let name: String
    let date: Date
    let distance: Double
    let duration: Double
    let routePath : [CLLocationCoordinate2D]

}

