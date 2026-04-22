import CoreLocation
import Foundation
import MapKit
import Observation

@MainActor
@Observable
final class CurrentLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var persistedValue: String
    var displayText: String
    var isRefreshing = false

    init(initialLocation: String = "") {
        let initialValue = initialLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        self.persistedValue = initialValue
        self.displayText = initialValue.isEmpty ? "Location unavailable" : initialValue

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func refresh() {
        guard CLLocationManager.locationServicesEnabled() else {
            applyUnavailableLocationState()
            return
        }

        isRefreshing = true
        displayText = persistedValue.isEmpty ? "Locating..." : persistedValue

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            applyUnavailableLocationState()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            applyUnavailableLocationState()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRefreshing else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .restricted, .denied:
            applyUnavailableLocationState()
        case .notDetermined:
            break
        @unknown default:
            applyUnavailableLocationState()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            applyUnavailableLocationState()
            return
        }

        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    applyUnavailableLocationState()
                    return
                }

                let mapItems = try await request.mapItems
                let formattedLocation = Self.formatLocation(from: mapItems.first)
                applyResolvedLocation(formattedLocation)
            } catch {
                applyUnavailableLocationState()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        applyUnavailableLocationState()
    }

    private func applyResolvedLocation(_ location: String) {
        isRefreshing = false
        persistedValue = location
        displayText = location
    }

    private func applyUnavailableLocationState() {
        isRefreshing = false
        persistedValue = ""
        displayText = "Location unavailable"
    }

    private static func formatLocation(from mapItem: MKMapItem?) -> String {
        guard let placemark = mapItem?.placemark else {
            return "Location unavailable"
        }

        let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea
        let country = placemark.country

        let components = [city, country].compactMap { $0 }.filter { !$0.isEmpty }

        if components.isEmpty {
            return "Location unavailable"
        }

        return components.joined(separator: ", ")
    }
}