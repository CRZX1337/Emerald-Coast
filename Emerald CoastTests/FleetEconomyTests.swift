import Foundation
import Testing
@testable import Emerald_Coast

@MainActor
struct FleetEconomyTests {
    private func fixture(value: Double = 156, tip: Double = 16) -> (GameStore, DeliveryOrder, DeliveryDriver) {
        let store = GameStore(saveKey: "fleet-test-\(UUID())")
        let order = DeliveryOrder(cityID: "oakland", strainID: Strains.base.id, grams: 28, value: value, tip: tip)
        let driver = DeliveryDriver(name: "Test", vehicle: .car)
        store.permittedDistrictIDs.insert(order.cityID)
        store.shelf = [ShelfItem(strainID: order.strainID, grams: 28, price: 10, unitCost: 1.2375)]
        store.orders = [order]
        store.drivers = [driver]
        return (store, order, driver)
    }

    @Test func oaklandLossRequiresCashBeforeGoodsLeave() throws {
        let (store, order, driver) = fixture()
        let quote = store.fleetQuote(for: order)
        #expect(quote.cashChangeCents == -12_000)
        #expect(quote.profitCents == -15_465)
        store.money = 119.99
        #expect(!store.dispatch(order: order, driver: driver))
        #expect(store.money == 119.99 && store.shelf.first?.grams == 28)
        #expect(store.orders == [order] && store.trips.isEmpty)
        store.money = 120
        #expect(store.dispatch(order: order, driver: driver))
        #expect(store.money == 0 && store.shelf.isEmpty)
        store.trips[0].duration = 0
        store.tickFleet()
        #expect(store.money == 0 && store.trips.isEmpty)
        #expect(store.deliveriesToday == 1)
    }

    @Test(arguments: [0, 1, -1]) func settlementUsesDispatchBasis(profitCents: Int) throws {
        let (store, order, driver) = fixture(value: 326.65 + Double(profitCents) / 100, tip: 0)
        store.money = 0
        let preview = store.fleetQuote(for: order)
        #expect(preview.profitCents == profitCents)
        #expect(store.dispatch(order: order, driver: driver))
        #expect(store.money == 0)
        store.stockShelf(with: order.strainID, grams: 50, unitCost: 9)
        let saved = try JSONEncoder().encode(store.trips)
        store.trips = try JSONDecoder().decode([DeliveryTrip].self, from: saved)
        let trip = try #require(store.trips.first)
        #expect(trip.quote == preview)
        store.trips[0].duration = 0
        store.tickFleet()
        store.tickFleet()
        #expect(store.money == Double(3465 + profitCents) / 100)
        #expect(store.deliveriesToday == 1 && store.shelf.first?.grams == 50)
    }

    @Test(arguments: [156, 300]) func oldTripWithoutQuoteKeepsOriginalPayout(value: Int) throws {
        let (store, order, driver) = fixture(value: Double(value), tip: 0)
        let trip = DeliveryTrip(order: order, driverID: driver.id, duration: 0)
        let data = try JSONEncoder().encode(trip)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["quote"] == nil)
        store.trips = [try JSONDecoder().decode(DeliveryTrip.self, from: data)]
        store.money = 0
        store.tickFleet()
        store.tickFleet()
        #expect(store.money == Double(max(0, value - 292)))
        #expect(store.deliveriesToday == 1)
    }
}
