import SwiftUI
import MapKit

// MARK: - Main View
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
        let content = BikeMapContentView(
            region: $region,
            bikes: bikes,
            selectedBike: $selectedBike,
            showingBikeDetail: $showingBikeDetail,
            locationManager: locationManager
        )
        
        let locationButton = LocationButtonView(region: $region, locationManager: locationManager)
        
        ZStack {
            content
            locationButton
            if locationManager.permissionDenied {
                PermissionDeniedView()
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
}

// MARK: - Map Content View
private struct BikeMapContentView: View {
    @Binding var region: MKCoordinateRegion
    let bikes: [Bike]
    @Binding var selectedBike: Bike?
    @Binding var showingBikeDetail: Bool
    let locationManager: LocationManager
    
    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        items.append(contentsOf: bikes.map { MapAnnotationItem.bike($0) })
        items.append(contentsOf: parkingZones.map { zone in
            MapAnnotationItem.parkingIcon(name: zone.name, coordinate: zone.iconCoordinate)
        })
        return items
    }
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: [.all],
            showsUserLocation: true,
            annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                MapAnnotationContent(
                    item: item,
                    selectedBike: $selectedBike,
                    showingBikeDetail: $showingBikeDetail
                )
            }
        }
        .overlay(ParkingZonesOverlayView(region: region))
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Map Annotation Content
private struct MapAnnotationContent: View {
    let item: MapAnnotationItem
    @Binding var selectedBike: Bike?
    @Binding var showingBikeDetail: Bool
    
    var body: some View {
        switch item {
        case .bike(let bike):
            BikeMapAnnotation(bike: bike, isSelected: bike.id == selectedBike?.id)
                .onTapGesture {
                    selectedBike = bike
                    showingBikeDetail = true
                }
        case .parkingIcon(let name, _):
            ParkingIconView(name: name)
        }
    }
}

// MARK: - Parking Icon View
private struct ParkingIconView: View {
    let name: String
    
    var body: some View {
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

// MARK: - Location Button View
private struct LocationButtonView: View {
    @Binding var region: MKCoordinateRegion
    let locationManager: LocationManager
    
    var body: some View {
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
    }
}

// MARK: - Permission Denied View
private struct PermissionDeniedView: View {
    var body: some View {
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

// MARK: - Parking Zones Overlay View
private struct ParkingZonesOverlayView: View {
    let region: MKCoordinateRegion
    
    var body: some View {
        GeometryReader { proxy in
            ForEach(parkingZones, id: \.name) { zone in
                ParkingZoneOverlay(
                    coordinates: zone.coordinates,
                    mapRect: MKMapRect(region),
                    frameSize: proxy.frame(in: .local).size
                )
            }
        }
    }
}

// MARK: - Parking Zone Overlay
private struct ParkingZoneOverlay: View {
    let coordinates: [CLLocationCoordinate2D]
    let mapRect: MKMapRect
    let frameSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            guard !coordinates.isEmpty else { return }
            
            let points = coordinates.map { coordinate -> CGPoint in
                let mapPoint = MKMapPoint(coordinate)
                let x = (mapPoint.x - mapRect.origin.x) * size.width / mapRect.size.width
                let y = (mapPoint.y - mapRect.origin.y) * size.height / mapRect.size.height
                return CGPoint(x: x, y: y)
            }
            
            var path = Path()
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
            
            context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 2)
            context.fill(path, with: .color(.blue.opacity(0.1)))
        }
    }
}