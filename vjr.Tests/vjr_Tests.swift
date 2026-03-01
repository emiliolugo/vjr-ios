//
//  vjr_Tests.swift
//  vjr.Tests
//
//  Created by Emilio Lugo on 2/28/26.
//

import Testing
@testable import vjr_

struct ContentViewModelTests {

    @Test func startsOnFeedTab() {
        let vm = ContentViewModel()
        #expect(vm.selectedTab == .feed)
    }

    @Test func tabSelectionChanges() {
        let vm = ContentViewModel()

        vm.selectedTab = .trips
        #expect(vm.selectedTab == .trips)

        vm.selectedTab = .friends
        #expect(vm.selectedTab == .friends)

        vm.selectedTab = .profile
        #expect(vm.selectedTab == .profile)

        vm.selectedTab = .feed
        #expect(vm.selectedTab == .feed)
    }

    @Test func showNewTripDefaultsFalse() {
        let vm = ContentViewModel()
        #expect(vm.showNewTrip == false)
    }

    @Test func showNewTripCanBeToggled() {
        let vm = ContentViewModel()
        vm.showNewTrip = true
        #expect(vm.showNewTrip == true)
        vm.showNewTrip = false
        #expect(vm.showNewTrip == false)
    }
}
