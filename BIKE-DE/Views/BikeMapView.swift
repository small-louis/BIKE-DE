import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var permissionDenied = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location only when moved by 10 meters
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            permissionDenied = false
        case .denied, .restricted:
            permissionDenied = true
            stopLocationUpdates()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            permissionDenied = false
        @unknown default:
            break
        }
    }
    
    func requestLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
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
    @State private var showingPermissionAlert = false
    
    init(bikes: [Bike] = sampleBikes) {
        _bikes = State(initialValue: bikes)
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: nil, annotationItems: bikes) { bike in
                MapAnnotation(coordinate: bike.coordinates) {
                    BikeMapAnnotation(bike: bike, isSelected: bike.id == selectedBike?.id)
                        .onTapGesture {
                            selectedBike = bike
                            showingBikeDetail = true
                        }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            if locationManager.permissionDenied {
                VStack {
                    Text("Location Access Required")
                        .font(.title)
                        .padding()
                    Text("Please enable location services in Settings to use all features of this app.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .padding()
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
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
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

#if DEBUG
struct BikeMapView_Previews: PreviewProvider {
    static var previews: some View {
        BikeMapView(bikes: sampleBikes)
    }
}
#endif 
