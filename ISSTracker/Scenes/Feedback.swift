//
//  Feedback.swift
//  ISSTracker
//
//  Created by Valerii Lider on 8/25/22.
//

import Foundation

enum Feedback {
    case updateISSLocation(CLLocationCoordinate2D)
    case noop
}
