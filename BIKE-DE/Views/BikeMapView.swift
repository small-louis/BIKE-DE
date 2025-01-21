import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

struct BikeMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.4827, longitude: -0.1277),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var bikes: [Bike]
    @State private var selectedBike: Bike?
    @State private var showingBikeDetail = false
    
    init(bikes: [Bike] = sampleBikes) {
        _bikes = State(initialValue: bikes)
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: bikes) { bike in
                MapAnnotation(coordinate: bike.coordinates) {
                    BikeMapAnnotation(bike: bike, isSelected: bike.id == selectedBike?.id)
                        .onTapGesture {
                            selectedBike = bike
                            showingBikeDetail = true
                        }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Overlay parking zones using iOS 15.6 compatible approach
            ForEach(parkingZones, id: \.name) { zone in
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100) // Fixed size for now
            }
        }
        .sheet(isPresented: $showingBikeDetail) {
            if let bike = selectedBike {
                BikeDetailView(bike: bike)
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
    
    // Helper function to convert coordinates to points
    private func convertCoordinateToPoint(coordinate: CLLocationCoordinate2D, in geometry: GeometryProxy) -> CGPoint {
        let mapRect = MKMapRect(region)
        let scale = geometry.size.width / mapRect.size.width
        
        let point = MKMapPoint(coordinate)
        let x = (point.x - mapRect.origin.x) * scale
        let y = (point.y - mapRect.origin.y) * scale
        
        return CGPoint(x: x, y: y)
    }
    
    // Helper function to calculate zone size based on map zoom
    private func calculateZoneSize(radius: Double, in region: MKCoordinateRegion) -> CGFloat {
        let metersPerPoint = MKMetersPerMapPointAtLatitude(region.center.latitude)
        return CGFloat(radius / metersPerPoint)
    }
    
    func isInParkingZone(location: CLLocation) -> Bool {
        for zone in parkingZones {
            let zoneLocation = CLLocation(latitude: zone.center.latitude, longitude: zone.center.longitude)
            if location.distance(from: zoneLocation) <= zone.radius {
                return true
            }
        }
        return false
    }
}

struct BikeMapAnnotation: View {
    let bike: Bike
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "bicycle")
                .font(.title)
                .foregroundColor(bike.isAvailable ? .green : .red)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                )
                .scaleEffect(isSelected ? 1.2 : 1.0)
            if isSelected {
                Text(bike.id)
                    .font(.caption)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
        }
    }
} 
