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

// Combined annotation type for both bikes and parking zones
enum MapItem: Identifiable {
    case bike(Bike)
    case parkingZone(ParkingZonePoint)
    
    var id: String {
        switch self {
        case .bike(let bike):
            return bike.id
        case .parkingZone(let point):
            return point.id.uuidString
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .bike(let bike):
            return bike.coordinates
        case .parkingZone(let point):
            return point.coordinate
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
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var isSimplifiedView = false
    
    init(bikes: [Bike] = sampleBikes) {
        _bikes = State(initialValue: bikes)
    }
    
    var body: some View {
        ZStack {
            MapWithOverlay(region: $region,
                          bikes: bikes,
                          selectedBike: $selectedBike,
                          showingBikeDetail: $showingBikeDetail,
                          userTrackingMode: $userTrackingMode,
                          isSimplifiedView: $isSimplifiedView)
            .edgesIgnoringSafeArea(.all)
            
            // Add buttons to the top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isSimplifiedView.toggle()
                    }) {
                        Image(systemName: isSimplifiedView ? "map" : "map.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
                
                // Location tracking button
                HStack {
                    Spacer()
                    Button(action: {
                        userTrackingMode = .follow
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
                if userTrackingMode == .follow {
                    region.center = location.coordinate
                }
            }
        }
    }
    
    // Helper function to create parking zone points
    private func parkingZoneAnnotations() -> [ParkingZonePoint] {
        var points: [ParkingZonePoint] = []
        for zone in parkingZones {
            // Create a grid of points to represent the parking zone
            let latitudes = stride(
                from: zone.coordinates[0].latitude,
                through: zone.coordinates[2].latitude,
                by: 0.0001 // Adjust density of points
            )
            let longitudes = stride(
                from: zone.coordinates[0].longitude,
                through: zone.coordinates[1].longitude,
                by: 0.0001 // Adjust density of points
            )
            
            for lat in latitudes {
                for lon in longitudes {
                    points.append(ParkingZonePoint(
                        coordinate: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        )
                    ))
                }
            }
        }
        return points
    }
    
    func isInParkingZone(location: CLLocation) -> Bool {
        for zone in parkingZones {
            let locationPoint = MKMapPoint(location.coordinate)
            let polygonPoints = zone.coordinates.map { MKMapPoint($0) }
            let polygon = MKPolygon(points: polygonPoints, count: polygonPoints.count)
            let polygonRenderer = MKPolygonRenderer(polygon: polygon)
            let mapPoint = MKMapPoint(location.coordinate)
            let polygonViewPoint = polygonRenderer.point(for: mapPoint)
            if polygonRenderer.path.contains(polygonViewPoint) {
                return true
            }
        }
        return false
    }
}

// Add ParkingAnnotation class
class ParkingAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String) {
        self.coordinate = coordinate
        self.title = title
        super.init()
    }
}

struct ParkingSymbolView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
            Text("P")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// Update MapWithOverlay
struct MapWithOverlay: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let bikes: [Bike]
    @Binding var selectedBike: Bike?
    @Binding var showingBikeDetail: Bool
    @Binding var userTrackingMode: MapUserTrackingMode
    @Binding var isSimplifiedView: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Configure map to hide default POIs and labels
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsCompass = false
        mapView.showsScale = false
        
        updateMapView(mapView)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = !isSimplifiedView
        
        // Ensure settings persist after updates
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsCompass = false
        mapView.showsScale = false
        
        updateMapView(mapView)
        
        // Update user tracking mode
        switch userTrackingMode {
        case .follow:
            mapView.setUserTrackingMode(.follow, animated: true)
        default:
            mapView.setUserTrackingMode(.none, animated: true)
        }
    }
    
    private func updateMapView(_ mapView: MKMapView) {
        // Remove all existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        if !isSimplifiedView {
            // Add bike annotations
            for bike in bikes {
                let annotation = BikeAnnotation(bike: bike)
                mapView.addAnnotation(annotation)
            }
            
            // Add parking zone overlays and symbols
            for zone in parkingZones {
                let polygon = MKPolygon(coordinates: zone.coordinates, count: zone.coordinates.count)
                polygon.title = zone.name
                mapView.addOverlay(polygon)
                
                let centerLat = zone.coordinates.map { $0.latitude }.reduce(0, +) / Double(zone.coordinates.count)
                let centerLon = zone.coordinates.map { $0.longitude }.reduce(0, +) / Double(zone.coordinates.count)
                let parkingAnnotation = ParkingAnnotation(
                    coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    title: zone.name
                )
                mapView.addAnnotation(parkingAnnotation)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapWithOverlay
        
        init(_ parent: MapWithOverlay) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let bikeAnnotation = annotation as? BikeAnnotation {
                let identifier = "BikeAnnotation"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ??
                    MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                let hostingController = UIHostingController(
                    rootView: BikeMapAnnotation(
                        bike: bikeAnnotation.bike,
                        isSelected: bikeAnnotation.bike.id == parent.selectedBike?.id
                    )
                )
                hostingController.view.backgroundColor = .clear
                view.addSubview(hostingController.view)
                view.frame.size = CGSize(width: 40, height: 40)
                view.canShowCallout = false
                return view
            } else if let parkingAnnotation = annotation as? ParkingAnnotation {
                let identifier = "ParkingAnnotation"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ??
                    MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                let hostingController = UIHostingController(rootView: ParkingSymbolView())
                hostingController.view.backgroundColor = .clear
                view.addSubview(hostingController.view)
                view.frame.size = CGSize(width: 30, height: 30)
                view.canShowCallout = true
                return view
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue.withAlphaComponent(0.7)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let bikeAnnotation = view.annotation as? BikeAnnotation else { return }
            parent.selectedBike = bikeAnnotation.bike
            parent.showingBikeDetail = true
        }
    }
}

class BikeAnnotation: NSObject, MKAnnotation {
    let bike: Bike
    var coordinate: CLLocationCoordinate2D { bike.coordinates }
    var title: String? { bike.id }
    
    init(bike: Bike) {
        self.bike = bike
        super.init()
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

struct UserLocationAnnotation: View {
    var body: some View {
        Image(systemName: "location.fill") // Use the arrow symbol here
            .font(.title)
            .foregroundColor(.blue)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
            )
    }
}

// Helper struct for parking zone visualization
struct ParkingZonePoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#if DEBUG
struct BikeMapView_Previews: PreviewProvider {
    static var previews: some View {
        BikeMapView(bikes: sampleBikes)
    }
}
#endif 
