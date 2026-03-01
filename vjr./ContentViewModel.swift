//
//  ContentViewModel.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import Observation

@Observable
final class ContentViewModel {
    enum Tab { case feed, trips, friends, profile }

    var selectedTab: Tab = .feed
    var showNewTrip = false
}
