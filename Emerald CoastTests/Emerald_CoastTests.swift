//
//  Emerald_CoastTests.swift
//  Emerald CoastTests
//
//  Regression tests for strain isolation and fleet order state.
//

import Testing
import Foundation
@testable import Emerald_Coast

@MainActor
struct StrainSelectionTests {

    private func makeStore() -> GameStore {
        GameStore(saveKey: "test-\(UUID().uuidString)")
    }

    @Test func roomSelectionsStayIndependent() throws {
        let store = makeStore()
        store.money = 100_000
        store.level = 10

        let breezy = try #require(Brands.brand(id: "breezy"))
        store.licenseBrand(breezy)
        let alternative = try #require(breezy.strains.first)

        store.selectedRoom = 0
        store.selectStrain(Strains.base)
        store.plant(in: 0)
        #expect(store.rooms[0].plant?.strainID == Strains.base.id)

        store.money = 100_000
        store.tapRoom(1)
        store.selectStrain(alternative)
        store.plant(in: 1)

        #expect(store.rooms[0].plant?.strainID == Strains.base.id)
        #expect(store.rooms[1].plant?.strainID == alternative.id)
        #expect(store.strain(for: store.rooms[0]).id == Strains.base.id)
        #expect(store.strain(for: store.rooms[1]).id == alternative.id)

        // Nach dem Wechsel zurück muss die Ursprungssorte wieder pflanzbar sein.
        store.rooms[0].plant = nil
        store.selectStrain(alternative)
        #expect(store.strain(for: store.rooms[0]).id == alternative.id)
        store.selectStrain(Strains.base)
        #expect(store.strain(for: store.rooms[0]).id == Strains.base.id)
        store.money = 100_000
        store.plant(in: 0)
        #expect(store.rooms[0].plant?.strainID == Strains.base.id)
    }

    @Test func switchingSelectionDoesNotRewriteFleetOrders() throws {
        let store = makeStore()
        store.money = 100_000
        store.level = 10

        let breezy = try #require(Brands.brand(id: "breezy"))
        store.licenseBrand(breezy)
        let alternative = try #require(breezy.strains.first)

        store.shelf = []
        store.stockShelf(with: Strains.base.id, grams: 120, unitCost: 2)
        store.stockShelf(with: alternative.id, grams: 120, unitCost: 2)
        store.drivers = [DeliveryDriver(name: "Test Driver", vehicle: .car)]
        store.orders = []
        store.spawnOrder()

        let order = try #require(store.orders.first)
        let assignedStrain = order.strainID

        store.selectedRoom = 0
        store.selectStrain(Strains.base)
        store.selectStrain(alternative)

        #expect(store.orders.first?.strainID == assignedStrain)
        #expect(store.orders.allSatisfy { $0.strainID == assignedStrain })
    }
}
