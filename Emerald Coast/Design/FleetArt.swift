//
//  FleetArt.swift
//  Emerald Coast
//
//  Gezeichnete kalifornische Karte mit Route und Fahrerposition.
//

import SwiftUI

/// Umriss Kaliforniens als Pfad, aus normalisierten Punkten gebaut.
struct CaliforniaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = DeliveryCities.outline
        guard let first = points.first else { return path }

        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
        }

        path.move(to: point(first))
        for p in points.dropFirst() {
            path.addLine(to: point(p))
        }
        path.closeSubpath()
        return path
    }
}

/// Karte mit Städten, Route und fahrendem Fahrzeug.
struct FleetMapView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            GeometryReader { geo in
                let size = geo.size

                ZStack {
                    CaliforniaShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.emerald.opacity(0.20),
                                    Theme.emerald.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    CaliforniaShape()
                        .stroke(Theme.emerald.opacity(0.55), lineWidth: 1.2)

                    // Route Humboldt → Ziel, je Fahrt eine Linie.
                    ForEach(store.trips) { trip in
                        let start = CGPoint(
                            x: DeliveryCities.home.x * size.width,
                            y: DeliveryCities.home.y * size.height
                        )
                        let end = CGPoint(
                            x: trip.order.city.x * size.width,
                            y: trip.order.city.y * size.height
                        )

                        Path { path in
                            path.move(to: start)
                            path.addLine(to: end)
                        }
                        .stroke(
                            Theme.lime.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                        )

                        Circle()
                            .fill(Theme.lime)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: tripVehicleIcon(trip))
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(Theme.onAccent)
                            )
                            .shadow(color: Theme.lime.opacity(0.9), radius: 7)
                            .position(
                                x: store.mapPosition(for: trip, now: context.date).x * size.width,
                                y: store.mapPosition(for: trip, now: context.date).y * size.height
                            )
                            .animation(.linear(duration: 0.5), value: store.progress(of: trip, now: context.date))
                    }

                    ForEach(DeliveryCities.all) { city in
                        cityPin(city, size: size)
                    }
                }
            }
        }
        .frame(height: 260)
    }

    private func tripVehicleIcon(_ trip: DeliveryTrip) -> String {
        store.drivers.first { $0.id == trip.driverID }?.vehicle.icon ?? "car.fill"
    }

    private func cityPin(_ city: DeliveryCity, size: CGSize) -> some View {
        let isHome = city.id == DeliveryCities.home.id

        return VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(isHome ? Theme.lime : Theme.emerald.opacity(0.9))
                    .frame(width: isHome ? 11 : 8, height: isHome ? 11 : 8)
                    .shadow(color: (isHome ? Theme.lime : Theme.emerald).opacity(0.9), radius: 6)
                if isHome {
                    Circle()
                        .stroke(Theme.lime.opacity(0.5), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }

            Text(city.name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(isHome ? Theme.lime : Color.white.opacity(0.75))
                .fixedSize()
        }
        .position(x: city.x * size.width, y: city.y * size.height)
    }
}

/// Kleines Fahrzeug-Piktogramm für Fahrer-Karten.
struct VehicleBadge: View {
    var vehicle: DeliveryVehicle
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: vehicle.icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(Theme.onAccent)
            .frame(width: size, height: size)
            .background(
                Circle().fill(
                    LinearGradient(
                        colors: [Theme.lime, Theme.emerald],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.28), lineWidth: 1))
    }
}
