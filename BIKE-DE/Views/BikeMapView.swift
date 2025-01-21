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

// Update MapAnnotationItem enum
enum MapAnnotationItem: Identifiable {
    case bike(Bike)
    case parkingIcon(name: String, coordinate: CLLocationCoordinate2D)
    
    var id: String {
        switch self {
        case .bike(let bike):
            return bike.id
        case .parkingIcon(let name, _):
            return "parkingIcon_\(name)"
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .bike(let bike):
            return bike.coordinates
        case .parkingIcon(_, let coordinate):
            return coordinate
        }
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
    
    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        // Add bikes (will be rendered under parking icons)
        items.append(contentsOf: bikes.map { MapAnnotationItem.bike($0) })
        // Add parking icons (will be rendered on top)
        items.append(contentsOf: parkingZones.map { zone in
            MapAnnotationItem.parkingIcon(name: zone.name, coordinate: zone.iconCoordinate)
        })
        return items
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                interactionModes: [.all],
                showsUserLocation: true,
                annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item {
                    case .bike(let bike):
                        BikeMapAnnotation(bike: bike, isSelected: bike.id == selectedBike?.id)
                            .onTapGesture {
                                selectedBike = bike
                                showingBikeDetail = true
                            }
                    case .parkingIcon(let name, _):
                        VStack {
                            Image(systemName: "p.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white))
                                .shadow(radius: 2)
                            Text(name)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                                .shadow(radius: 2)
                        }
                    }
                }
            }
            .overlay(
                GeometryReader { proxy in
                    ForEach(parkingZones, id: \.name) { zone in
                        let rect = proxy.frame(in: .local)
                        ParkingZoneOverlay(coordinates: zone.coordinates, mapRect: MKMapRect(region), frameSize: rect.size)
                    }
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Location tracking button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let location = locationManager.location {
                            region.center = location.coordinate
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            
            // Permission denied overlay
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
            if let location = locationManager.location {
                region.center = location.coordinate
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
    }
    
    func isInParkingZone(location: CLLocation) -> Bool {
        for zone in parkingZones {
            // Convert the location to MKMapPoint
            let locationPoint = MKMapPoint(location.coordinate)
            
            // Convert zone coordinates to points
            let zonePoints = zone.coordinates.map { MKMapPoint($0) }
            
            // Create a polygon from the points
            let polygon = MKPolygon(points: zonePoints, count: zonePoints.count)
            
            // Check if the location point is inside the polygon
            let mapRect = MKMapRect(x: locationPoint.x, y: locationPoint.y, width: 0.1, height: 0.1)
            if polygon.intersects(mapRect) {
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

// Updated iOS 15.6 compatible parking zone overlay
struct ParkingZoneOverlay: View {
    let coordinates: [CLLocationCoordinate2D]
    let mapRect: MKMapRect
    let frameSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            var path = Path()
            guard let first = coordinates.first else { return }
            
            let points = coordinates.map { coordinate -> CGPoint in
                let mapPoint = MKMapPoint(coordinate)
                let x = (mapPoint.x - mapRect.origin.x) * size.width / mapRect.size.width
                let y = (mapPoint.y - mapRect.origin.y) * size.height / mapRect.size.height
                return CGPoint(x: x, y: y)
            }
            
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
            
            context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 2)
            context.fill(path, with: .color(.blue.opacity(0.1)))
        }
    }
}

#if DEBUG
struct BikeMapView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BikeMapView(bikes: sampleBikes)
                .previewDisplayName("Map View")
                .previewDevice("iPhone 13")
            
            BikeMapView(bikes: sampleBikes)
                .previewDisplayName("Map View (Dark)")
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 13")
        }
    }
}
#endif 
