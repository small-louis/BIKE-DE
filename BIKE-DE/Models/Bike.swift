//
//  Bike.swift
//  BIKE-DE
//
//  Created by Louis Brouwer on 21/01/2025.
//

import Foundation
import CoreLocation

struct Bike: Identifiable, Codable {
    var id: String
    var location: String
    var isAvailable: Bool
    var lockCode: String
    var coordinates: CLLocationCoordinate2D
    
    // Custom coding keys to handle CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, location, isAvailable, lockCode
        case latitude, longitude
    }
    
    init(id: String, location: String, isAvailable: Bool, lockCode: String, coordinates: CLLocationCoordinate2D) {
        self.id = id
        self.location = location
        self.isAvailable = isAvailable
        self.lockCode = lockCode
        self.coordinates = coordinates
    }
    
    // Custom encoding for coordinates
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(location, forKey: .location)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encode(lockCode, forKey: .lockCode)
        try container.encode(coordinates.latitude, forKey: .latitude)
        try container.encode(coordinates.longitude, forKey: .longitude)
    }
    
    // Custom decoding for coordinates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        location = try container.decode(String.self, forKey: .location)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        lockCode = try container.decode(String.self, forKey: .lockCode)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Define parking zones
struct ParkingZone {
    let center: CLLocationCoordinate2D
    let radius: Double // in meters
    let name: String
}

// Sample data for testing
let parkingZones: [ParkingZone] = [
    ParkingZone(
        center: CLLocationCoordinate2D(latitude: 51.4827, longitude: -0.1277), // Battersea
        radius: 50,
        name: "Battersea Campus"
    ),
    ParkingZone(
        center: CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246), // Kensington
        radius: 50,
        name: "Kensington Campus"
    )
]

let sampleBikes: [Bike] = [
    Bike(id: "bike1", location: "Campus A", isAvailable: true, lockCode: "1234",
         coordinates: CLLocationCoordinate2D(latitude: 51.4792, longitude: -0.1689)),
    Bike(id: "bike2", location: "Campus B", isAvailable: true, lockCode: "5678",
         coordinates: CLLocationCoordinate2D(latitude: 51.4978, longitude: -0.1740)),
    // ... add coordinates for other bikes
]


